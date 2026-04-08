import { existsSync, readFileSync } from 'fs';

/**
 * 为 Write/Edit 工具生成简化 diff。
 * 对比现有文件内容和新内容，输出 Git-style unified diff。
 */
export function generateDiff(
  toolName: string,
  toolInput: Record<string, unknown>,
): string | undefined {
  const name = toolName.toLowerCase();

  if (name === 'write') {
    const filePath = (toolInput.file_path ?? toolInput.path) as string | undefined;
    const newContent = toolInput.content as string | undefined;
    if (!filePath || !newContent) return undefined;

    // 读取现有文件
    let oldContent = '';
    if (existsSync(filePath)) {
      try { oldContent = readFileSync(filePath, 'utf-8'); } catch { /* new file */ }
    }

    return unifiedDiff(filePath, oldContent, newContent);
  }

  if (name === 'edit') {
    const filePath = (toolInput.file_path ?? toolInput.path) as string | undefined;
    const oldStr = toolInput.old_string as string | undefined;
    const newStr = toolInput.new_string as string | undefined;
    if (!filePath || !oldStr || !newStr) return undefined;

    const lines: string[] = [
      `--- a/${filePath}`,
      `+++ b/${filePath}`,
      '@@ edit @@',
    ];
    for (const line of oldStr.split('\n')) lines.push(`-${line}`);
    for (const line of newStr.split('\n')) lines.push(`+${line}`);
    return lines.join('\n');
  }

  return undefined;
}

/** 简化的 unified diff 生成（逐行对比） */
function unifiedDiff(path: string, oldText: string, newText: string): string {
  const oldLines = oldText.split('\n');
  const newLines = newText.split('\n');
  const lines: string[] = [
    `--- a/${path}`,
    `+++ b/${path}`,
  ];

  if (oldText === '') {
    // 新文件
    lines.push(`@@ -0,0 +1,${newLines.length} @@ (new file)`);
    for (const l of newLines) lines.push(`+${l}`);
    return lines.join('\n');
  }

  // 简单逐行 diff（适合短文件，长文件截断）
  const maxLines = 50;
  lines.push(`@@ -1,${Math.min(oldLines.length, maxLines)} +1,${Math.min(newLines.length, maxLines)} @@`);

  const maxI = Math.max(oldLines.length, newLines.length);
  let shown = 0;

  for (let i = 0; i < maxI && shown < maxLines; i++) {
    const old = i < oldLines.length ? oldLines[i] : null;
    const nw = i < newLines.length ? newLines[i] : null;

    if (old === nw) {
      lines.push(` ${old}`);
    } else {
      if (old != null) lines.push(`-${old}`);
      if (nw != null) lines.push(`+${nw}`);
    }
    shown++;
  }

  if (maxI > maxLines) {
    lines.push(`... (${maxI - maxLines} more lines)`);
  }

  return lines.join('\n');
}
