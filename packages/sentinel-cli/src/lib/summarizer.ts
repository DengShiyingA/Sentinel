import { basename } from 'path';

/**
 * Convert tool call results into human-readable one-line summaries.
 */
export function summarize(toolName: string, toolInput: Record<string, unknown>, toolResponse?: string): string {
  const filePath = (toolInput.file_path ?? toolInput.path ?? '') as string;
  const fileName = filePath ? basename(filePath) : '';
  const command = (toolInput.command ?? '') as string;

  switch (toolName) {
    case 'Write':
      return `${fileName || 'file'} written`;
    case 'Edit':
      return `${fileName || 'file'} edited`;
    case 'Read':
      return `${fileName || 'file'} read`;
    case 'Bash': {
      const cmd = command.length > 40 ? command.slice(0, 37) + '...' : command;
      const ok = !toolResponse?.includes('error') && !toolResponse?.includes('Error');
      return `${cmd || 'command'}${ok ? '' : ' (error)'}`;
    }
    case 'Glob':
      return `search: ${(toolInput.pattern ?? '*') as string}`;
    case 'Grep':
      return `grep: ${(toolInput.pattern ?? '') as string}`;
    case 'WebSearch':
      return `search: ${(toolInput.query ?? '') as string}`;
    case 'WebFetch':
      return `fetch: ${(toolInput.url ?? '') as string}`;
    default:
      return `${toolName} completed`;
  }
}

export function summarizeStop(reason: string): string {
  switch (reason) {
    case 'completed': case 'end_turn': return 'Task completed';
    case 'error': return 'Task failed';
    case 'interrupted': return 'Task interrupted';
    default: return `Stopped: ${reason}`;
  }
}
