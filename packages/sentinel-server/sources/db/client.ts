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
    CREATE TABLE IF NOT EXISTS "AuditLog" (
      "id"          TEXT PRIMARY KEY,
      "requestId"   TEXT,
      "action"      TEXT NOT NULL,
      "deviceId"    TEXT NOT NULL,
      "toolName"    TEXT,
      "riskLevel"   TEXT,
      "details"     TEXT,
      "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    CREATE INDEX IF NOT EXISTS "idx_audit_createdat" ON "AuditLog" ("createdAt" DESC);
    CREATE TABLE IF NOT EXISTS "RevokedToken" (
      "deviceId"   TEXT PRIMARY KEY,
      "reason"     TEXT NOT NULL DEFAULT 'manual',
      "revokedAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS "PairSecret" (
      "secret"      TEXT PRIMARY KEY,
      "macDeviceId" TEXT NOT NULL,
      "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      "expiresAt"   TIMESTAMP(3) NOT NULL
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
    CREATE INDEX IF NOT EXISTS "idx_device_publickey" ON "Device" ("publicKey");
    CREATE INDEX IF NOT EXISTS "idx_device_pairedwith" ON "Device" ("pairedWithId");
    CREATE INDEX IF NOT EXISTS "idx_approval_status" ON "ApprovalRequest" ("status");
    CREATE INDEX IF NOT EXISTS "idx_approval_macdevice" ON "ApprovalRequest" ("macDeviceId");
    CREATE INDEX IF NOT EXISTS "idx_rule_deviceid" ON "Rule" ("deviceId");
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

// ==================== AuditLog ====================

export interface AuditEntry {
  id: string;
  requestId: string | null;
  action: string;
  deviceId: string;
  toolName: string | null;
  riskLevel: string | null;
  details: string | null;
  createdAt: Date;
}

export async function appendAuditLog(entry: {
  requestId?: string;
  action: string;
  deviceId: string;
  toolName?: string;
  riskLevel?: string;
  details?: string;
}): Promise<void> {
  await db.query(
    `INSERT INTO "AuditLog" ("id", "requestId", "action", "deviceId", "toolName", "riskLevel", "details")
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [
      `audit-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      entry.requestId ?? null,
      entry.action,
      entry.deviceId,
      entry.toolName ?? null,
      entry.riskLevel ?? null,
      entry.details ?? null,
    ],
  );
}

export async function getRecentAuditLogs(limit = 100): Promise<AuditEntry[]> {
  const r = await db.query<AuditEntry>(
    'SELECT * FROM "AuditLog" ORDER BY "createdAt" DESC LIMIT $1',
    [limit],
  );
  return r.rows;
}

// ==================== RevokedToken ====================

export async function revokeToken(deviceId: string, reason: string): Promise<void> {
  await db.query(
    `INSERT INTO "RevokedToken" ("deviceId", "reason") VALUES ($1, $2)
     ON CONFLICT ("deviceId") DO UPDATE SET "reason" = $2, "revokedAt" = NOW()`,
    [deviceId, reason],
  );
}

export async function isTokenRevoked(deviceId: string): Promise<boolean> {
  const r = await db.query('SELECT 1 FROM "RevokedToken" WHERE "deviceId" = $1', [deviceId]);
  return (r.rows?.length ?? 0) > 0;
}

export async function unrevokeToken(deviceId: string): Promise<void> {
  await db.query('DELETE FROM "RevokedToken" WHERE "deviceId" = $1', [deviceId]);
}

// ==================== PairSecret ====================

export interface PairSecretRow {
  secret: string;
  macDeviceId: string;
  createdAt: Date;
  expiresAt: Date;
}

export async function createPairSecret(secret: string, macDeviceId: string, ttlSeconds: number): Promise<void> {
  await db.query(
    `INSERT INTO "PairSecret" ("secret", "macDeviceId", "expiresAt")
     VALUES ($1, $2, NOW() + INTERVAL '1 second' * $3)
     ON CONFLICT ("secret") DO UPDATE SET "macDeviceId" = $2, "expiresAt" = NOW() + INTERVAL '1 second' * $3`,
    [secret, macDeviceId, ttlSeconds],
  );
}

export async function findPairSecret(secret: string): Promise<PairSecretRow | null> {
  const r = await db.query<PairSecretRow>(
    'SELECT * FROM "PairSecret" WHERE "secret" = $1 AND "expiresAt" > NOW()',
    [secret],
  );
  return r.rows[0] ?? null;
}

export async function deletePairSecret(secret: string): Promise<void> {
  await db.query('DELETE FROM "PairSecret" WHERE "secret" = $1', [secret]);
}

export async function cleanExpiredPairSecrets(): Promise<void> {
  await db.query('DELETE FROM "PairSecret" WHERE "expiresAt" <= NOW()');
}

// ==================== Transactions ====================

export async function pairDevicesTransaction(
  macDeviceId: string,
  iosDeviceId: string,
  secret: string,
  apnsToken?: string,
): Promise<void> {
  await db.query('BEGIN');
  try {
    await db.query('UPDATE "Device" SET "pairedWithId" = $2 WHERE "id" = $1', [macDeviceId, iosDeviceId]);
    if (apnsToken) {
      await db.query('UPDATE "Device" SET "pairedWithId" = $2, "apnsToken" = $3 WHERE "id" = $1', [iosDeviceId, macDeviceId, apnsToken]);
    } else {
      await db.query('UPDATE "Device" SET "pairedWithId" = $2 WHERE "id" = $1', [iosDeviceId, macDeviceId]);
    }
    await db.query('DELETE FROM "PairSecret" WHERE "secret" = $1', [secret]);
    await db.query('COMMIT');
  } catch (err) {
    await db.query('ROLLBACK');
    throw err;
  }
}

// ==================== Cleanup ====================

/** Remove approval requests older than 24 hours to prevent DB bloat */
export async function cleanExpiredApprovals(): Promise<number> {
  const r = await db.query(
    `DELETE FROM "ApprovalRequest" WHERE "createdAt" < NOW() - INTERVAL '24 hours' AND "status" != 'pending'`,
  );
  return r.affectedRows ?? 0;
}

/** Mark stale pending requests as timed out */
export async function expireStalePendingRequests(timeoutSeconds: number): Promise<number> {
  const r = await db.query(
    `UPDATE "ApprovalRequest" SET "status" = 'timeout', "resolvedAt" = NOW()
     WHERE "status" = 'pending' AND "createdAt" < NOW() - INTERVAL '1 second' * $1`,
    [timeoutSeconds],
  );
  return r.affectedRows ?? 0;
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
