import { describe, test } from 'node:test';
import assert from 'node:assert';

/**
 * Unit tests for the rules engine glob matching and rule matching logic.
 * Uses Node.js built-in test runner (no extra dependencies).
 *
 * Run: npx tsx --test src/__tests__/rules-engine.test.ts
 */

// Inline the globMatch function to test independently
function globMatch(pattern: string, value: string): boolean {
  const regex = pattern
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/\*\*/g, '{{DOUBLESTAR}}')
    .replace(/\*/g, '[^/]*')
    .replace(/{{DOUBLESTAR}}/g, '.*');
  return new RegExp(`^${regex}$`).test(value);
}

describe('globMatch', () => {
  test('exact match', () => {
    assert.strictEqual(globMatch('Bash', 'Bash'), true);
    assert.strictEqual(globMatch('Bash', 'Write'), false);
  });

  test('single wildcard (*)', () => {
    assert.strictEqual(globMatch('Edit*', 'Edit'), true);
    assert.strictEqual(globMatch('Edit*', 'EditFile'), true);
    assert.strictEqual(globMatch('*.ts', 'foo.ts'), true);
    assert.strictEqual(globMatch('*.ts', 'foo/bar.ts'), false); // * doesn't cross /
  });

  test('double wildcard (**)', () => {
    assert.strictEqual(globMatch('**/.env*', '/home/user/.env'), true);
    assert.strictEqual(globMatch('**/.env*', '/home/user/.env.local'), true);
    assert.strictEqual(globMatch('**/.env*', '.env'), true);
    assert.strictEqual(globMatch('src/**/*.ts', 'src/foo/bar.ts'), true);
    assert.strictEqual(globMatch('src/**/*.ts', 'src/a/b/c.ts'), true);
  });

  test('/tmp/** pattern', () => {
    assert.strictEqual(globMatch('/tmp/**', '/tmp/foo.txt'), true);
    assert.strictEqual(globMatch('/tmp/**', '/tmp/a/b/c'), true);
    assert.strictEqual(globMatch('/tmp/**', '/home/tmp/foo'), false);
  });

  test('**/secrets/** pattern', () => {
    assert.strictEqual(globMatch('**/secrets/**', '/app/secrets/key.pem'), true);
    assert.strictEqual(globMatch('**/secrets/**', 'secrets/a'), true);
    assert.strictEqual(globMatch('**/secrets/**', '/x/secrets/a/b'), true);
  });

  test('special regex characters in pattern', () => {
    assert.strictEqual(globMatch('file.name.ts', 'file.name.ts'), true);
    assert.strictEqual(globMatch('file.name.ts', 'filexnamexts'), false);
  });
});

describe('rule priority sorting', () => {
  test('lower priority number wins', () => {
    const rules = [
      { id: 'a', priority: 20 },
      { id: 'b', priority: 1 },
      { id: 'c', priority: 10 },
    ];
    const sorted = [...rules].sort((a, b) => a.priority - b.priority);
    assert.strictEqual(sorted[0].id, 'b');
    assert.strictEqual(sorted[1].id, 'c');
    assert.strictEqual(sorted[2].id, 'a');
  });
});
