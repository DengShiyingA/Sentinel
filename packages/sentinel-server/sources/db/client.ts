import { PGlite } from '@electric-sql/pglite';
import { logger } from '../lib/logger';
import { config } from '../lib/config';

let db: PGlite;

export async function initDatabase(): Promise<void> {
  const dataDir = config.DATA_DIR;
  logger.info({ dataDir }, 'Initializing PGlite');

  db = new PGlite(dataDir);
  await db.waitReady;
  await runMigrations();

  logger.info('PGlite initialized');
}

async function runMigrations(): Promise<void> {
  logger.info('Running migrations');
  await db.exec(`
    CREATE TABLE IF NOT EXISTS "Device" (
      "id"           TEXT PRIMARY KEY,
      "publicKey"    TEXT UNIQUE NOT NULL,
      "type"         TEXT NOT NULL,
      "name"         TEXT NOT NULL,
      "pairedWithId" TEXT,
      "apnsToken"    TEXT,
      "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS "ApprovalRequest" (
      "id"          TEXT PRIMARY KEY,
      "macDeviceId" TEXT NOT NULL,
      "toolName"    TEXT NOT NULL,
      "toolInput"   JSONB NOT NULL,
      "riskLevel"   TEXT NOT NULL DEFAULT 'low',
      "status"      TEXT NOT NULL DEFAULT 'pending',
      "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      "resolvedAt"  TIMESTAMP(3)
    );
    CREATE TABLE IF NOT EXISTS "Rule" (
      "id"          TEXT PRIMARY KEY,
      "deviceId"    TEXT NOT NULL,
      "toolPattern" TEXT,
      "pathPattern" TEXT,
      "risk"        TEXT NOT NULL DEFAULT 'require_confirm',
      "priority"    INTEGER NOT NULL DEFAULT 100,
      "description" TEXT,
      "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  `);
  logger.info('Migrations complete');
}

// ==================== Device ====================

export interface Device {
  id: string;
  publicKey: string;
  type: string;
  name: string;
  pairedWithId: string | null;
  apnsToken: string | null;
}

export async function findDeviceById(id: string): Promise<Device | null> {
  const r = await db.query<Device>('SELECT * FROM "Device" WHERE "id" = $1', [id]);
  return r.rows[0] ?? null;
}

export async function findDeviceByPublicKey(publicKey: string): Promise<Device | null> {
  const r = await db.query<Device>('SELECT * FROM "Device" WHERE "publicKey" = $1', [publicKey]);
  return r.rows[0] ?? null;
}

export async function upsertDevice(d: { id: string; publicKey: string; type: string; name: string }): Promise<Device> {
  const r = await db.query<Device>(
    `INSERT INTO "Device" ("id", "publicKey", "type", "name")
     VALUES ($1, $2, $3, $4)
     ON CONFLICT ("publicKey") DO UPDATE SET "name" = $4, "type" = $3
     RETURNING *`,
    [d.id, d.publicKey, d.type, d.name],
  );
  return r.rows[0];
}

export async function updateDevicePairing(id: string, pairedWithId: string, apnsToken?: string): Promise<void> {
  if (apnsToken) {
    await db.query('UPDATE "Device" SET "pairedWithId" = $2, "apnsToken" = $3 WHERE "id" = $1', [id, pairedWithId, apnsToken]);
  } else {
    await db.query('UPDATE "Device" SET "pairedWithId" = $2 WHERE "id" = $1', [id, pairedWithId]);
  }
}

// ==================== ApprovalRequest ====================

export interface ApprovalRow {
  id: string;
  macDeviceId: string;
  toolName: string;
  toolInput: any;
  riskLevel: string;
  status: string;
  createdAt: Date;
  resolvedAt: Date | null;
}

export async function createApproval(a: { id: string; macDeviceId: string; toolName: string; toolInput: any; riskLevel: string }): Promise<ApprovalRow> {
  const r = await db.query<ApprovalRow>(
    `INSERT INTO "ApprovalRequest" ("id", "macDeviceId", "toolName", "toolInput", "riskLevel")
     VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [a.id, a.macDeviceId, a.toolName, JSON.stringify(a.toolInput), a.riskLevel],
  );
  return r.rows[0];
}

export async function resolveApproval(id: string, status: string): Promise<number> {
  const r = await db.query(
    `UPDATE "ApprovalRequest" SET "status" = $2, "resolvedAt" = NOW() WHERE "id" = $1 AND "status" = 'pending'`,
    [id, status],
  );
  return r.affectedRows ?? 0;
}

export async function findApprovalById(id: string): Promise<ApprovalRow | null> {
  const r = await db.query<ApprovalRow>('SELECT * FROM "ApprovalRequest" WHERE "id" = $1', [id]);
  return r.rows[0] ?? null;
}

// ==================== Health ====================

export async function healthCheck(): Promise<boolean> {
  try {
    await db.query('SELECT 1');
    return true;
  } catch {
    return false;
  }
}

export async function shutdownDatabase(): Promise<void> {
  if (db) await db.close();
  logger.info('Database shut down');
}
