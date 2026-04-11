// packages/sentinel-cli/src/lib/yolo.ts
//
// YOLO mode: auto-approve all tool calls without sending to iOS.
// Set once at CLI startup via `sentinel run --yolo`, never persisted.
// Each `sentinel run` must explicitly opt in.

let yoloEnabled = false;

export function setYolo(enabled: boolean): void {
  yoloEnabled = enabled;
}

export function isYolo(): boolean {
  return yoloEnabled;
}
