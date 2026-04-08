# CLAUDE.md — Sentinel Project Guide

## Project Identity

**Name:** Sentinel  
**Tagline:** The security gate between AI agents and your system  
**Positioning:** Not a terminal mirror — a Human-in-the-Loop approval engine for Claude Code

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code (Host Mac)                     │
│  PreToolUse ──→ POST /hook ──→ sentinel-cli (:7749)         │
│  PostToolUse ──→ POST /event                                 │
│  Stop ──→ POST /event                                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
     LAN (TCP)    Server (WS)   iCloud
     :7750        :3005          CloudKit
     Bonjour      JWT+E2EE      Apple ID
          │            │            │
          └────────────┼────────────┘
                       │
┌──────────────────────┴──────────────────────────────────────┐
│                    Mobile App (Flutter)                       │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐ │
│  │ Approval │  │ Terminal  │  │ Messages │  │  Settings   │ │
│  │ Engine   │  │ Stream   │  │ + Chat   │  │  + Rules    │ │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘ │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Transport Layer (LAN / Server / CloudKit)             │   │
│  │ E2EE: libsodium secretbox (XSalsa20-Poly1305)       │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

## Module Breakdown

### sentinel-cli (Node.js) — EXISTING, extend
- Hook server (:7749) — intercepts Claude Code tool calls
- Transport layer — LAN TCP / Socket.IO / CloudKit polling
- Rule engine — glob matching, permission modes, custom rules
- Session logging — full conversation recording
- Daemon — background service with caffeinate + launchd

### sentinel-server (Node.js) — EXISTING, extend  
- PGlite embedded DB (zero external deps)
- JWT auth with Ed25519 challenge-response
- Socket.IO relay for remote mode
- Multi-device decision sync

### sentinel-app (Flutter) — NEW, replaces SwiftUI
- Cross-platform: iOS, Android, Web
- 3-tab layout: Approval (with terminal + history) / Messages / Settings
- Biometric gating (Face ID / fingerprint)
- Local notifications with quick actions

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Mobile | Flutter 3.x (Dart) | One codebase, iOS + Android + Web |
| CLI | Node.js 20, TypeScript | Already built, stable |
| Server | Fastify + Socket.IO + PGlite | Already built, zero-dep DB |
| Encryption | libsodium (sodium_plus) | XSalsa20-Poly1305, cross-platform |
| Auth | Ed25519 + JWT | Already implemented |
| LAN | TCP + mDNS/Bonjour | Zero-config discovery |
| Push | FCM (Android) + APNs (iOS) | Platform native |
| State | Riverpod (Flutter) | Reactive, testable |

## MVP Phases

### Phase 1 — Feature Parity (2 weeks)
Port current SwiftUI app to Flutter:
- [ ] Approval list with swipe actions
- [ ] Terminal view (streaming text)  
- [ ] Activity feed / message history
- [ ] Settings (connection mode picker, manual connect)
- [ ] LAN transport (TCP + mDNS discovery)
- [ ] Server transport (Socket.IO + JWT)
- [ ] Biometric auth (local_auth package)
- [ ] Local notifications
- [ ] Rule viewer
- [ ] Onboarding flow

### Phase 2 — Beat Happy Coder (2 weeks)
Features Happy doesn't have:
- [ ] Diff viewer — show file changes before approval (syntax highlighted)
- [ ] AI intent preview — "Claude wants to refactor auth module" summary
- [ ] Batch approval — approve multiple pending requests at once
- [ ] Temporary trust — "allow Write for next 5 minutes"
- [ ] Smart rule suggestions — auto-suggest rules based on approval patterns
- [ ] Budget dashboard with charts
- [ ] Permission modes UI (strict/relaxed/yolo/plan/lockdown)
- [ ] Android support (Flutter gives us this free)
- [ ] Web dashboard (Flutter Web)

### Phase 3 — Killer Features (2 weeks)
- [ ] Sandbox preview — dry-run tool calls in isolated env before approval
- [ ] AI summary — Claude summarizes terminal output in real-time
- [ ] Voice quick reply — Siri Shortcuts / voice-to-text for chat
- [ ] Live Activity (iOS) — lock screen widget showing active session
- [ ] Home Screen Widget — pending count + connection status
- [ ] Session playback — replay past sessions step by step
- [ ] Team mode — multiple users approve different risk levels
- [ ] Audit export — PDF/CSV audit trail for compliance

## Project Structure

```
sentinel/
├── packages/
│   ├── sentinel-cli/          # Node.js CLI (existing)
│   │   └── src/
│   ├── sentinel-server/       # Relay server (existing)  
│   │   └── sources/
│   └── sentinel-app/          # Flutter app (NEW)
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app/
│       │   │   ├── app.dart
│       │   │   ├── router.dart
│       │   │   └── theme.dart
│       │   ├── features/
│       │   │   ├── approval/
│       │   │   │   ├── models/
│       │   │   │   ├── providers/
│       │   │   │   ├── screens/
│       │   │   │   └── widgets/
│       │   │   ├── terminal/
│       │   │   ├── messages/
│       │   │   ├── rules/
│       │   │   ├── settings/
│       │   │   └── onboarding/
│       │   ├── core/
│       │   │   ├── transport/
│       │   │   │   ├── transport.dart        # Abstract interface
│       │   │   │   ├── lan_transport.dart     # TCP + mDNS
│       │   │   │   ├── server_transport.dart  # Socket.IO
│       │   │   │   └── cloudkit_transport.dart
│       │   │   ├── crypto/
│       │   │   │   └── encryption.dart       # libsodium wrapper
│       │   │   ├── auth/
│       │   │   │   └── biometric.dart        # Face ID / fingerprint
│       │   │   ├── notifications/
│       │   │   └── storage/
│       │   └── shared/
│       │       ├── models/
│       │       ├── widgets/
│       │       └── utils/
│       ├── android/
│       ├── ios/
│       ├── web/
│       ├── test/
│       └── pubspec.yaml
├── Sentinel/                  # Legacy SwiftUI app (kept for reference)
├── docs/
├── install.sh
├── docker-compose.yml
├── README.md
└── CLAUDE.md                  # This file
```

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Flutter TCP socket on iOS | mDNS/Bonjour may need native plugin | Use flutter_nsd + raw TCP via dart:io Socket |
| E2EE key exchange | libsodium not native in Dart | Use sodium_libs package (C FFI bindings) |
| Background execution | iOS kills background TCP | Use background_fetch + local notifications |
| Biometric on Android | Fragmented APIs | local_auth package handles all variants |
| Web transport | No raw TCP in browsers | Use WebSocket fallback (server mode only) |
| Flutter Web push | No FCM in PWA | Use web push API via firebase_messaging |
| Performance | Terminal streaming 60fps | Use CustomScrollView + selective rebuild |
| App Store review | Claude Code integration | Frame as "developer tool", not "AI proxy" |

## Code Conventions

### Dart/Flutter
- Riverpod for state management (NOT Provider, NOT BLoC)
- Feature-first folder structure
- Freezed for immutable models
- go_router for navigation
- Null safety enforced (no `!` force unwrap)
- Tests: unit for logic, widget for UI, integration for flows

### TypeScript (CLI/Server)
- Strict mode, no `any` where avoidable
- Zod for all input validation
- Pino for logging
- ESM imports preferred

### General
- All user-facing strings localized (intl package)
- Dark mode support from day 1
- Min targets: iOS 15, Android API 26, Chrome 90
- Max 3 levels of widget nesting before extracting
- No God classes — max 200 lines per file

## Absolute Rules (NEVER violate)

1. **NEVER** introduce third-party cloud services (no Firebase Auth, no Supabase, no AWS)
   - Exception: FCM/APNs for push notifications only (payload must be opaque)
2. **NEVER** transmit unencrypted user data over network
   - LAN mode: libsodium secretbox after key exchange
   - Server mode: TLS + E2EE payload
3. **NEVER** store secrets (keys, tokens) in plaintext
   - Use flutter_secure_storage (Keychain/Keystore)
4. **NEVER** auto-approve without user consent
   - Even in "yolo" mode, log everything
5. **NEVER** send file contents through push notifications
   - Push payload: risk level + tool name only
6. **NEVER** use `setState` in Flutter (use Riverpod)
7. **NEVER** import platform-specific code without conditional imports
8. **NEVER** hard-code server URLs or ports

## Competitive Advantages over Happy Coder

| Capability | Happy | Sentinel | How |
|-----------|-------|----------|-----|
| Smart rules | ❌ | ✅ | Glob matching + modes + hot reload |
| Biometric gate | ❌ | ✅ | Face ID / fingerprint on high-risk ops |
| Zero cloud | ❌ | ✅ | LAN-first, server optional |
| Diff preview | ❌ | ✅ Phase 2 | Show file changes before approval |
| Budget control | ❌ | ✅ | Daily limits + cost tracking |
| Cross-platform | React Native | Flutter | Dart + native perf |
| E2EE default | Opt-in | Always on | libsodium, no server can read |
| Permission modes | 4 | 5 | strict/relaxed/yolo/plan/lockdown |
| Sandbox preview | ❌ | ✅ Phase 3 | Dry-run in container |
| AI summary | ❌ | ✅ Phase 3 | Real-time terminal digests |
| Live Activity | ❌ | ✅ Phase 3 | iOS lock screen session widget |
| Audit trail | ❌ | ✅ Phase 3 | Compliance-ready export |

## Getting Started

```bash
# CLI (existing)
cd packages/sentinel-cli && npm install && npm run build
sentinel install && sentinel start

# Flutter App (new)
cd packages/sentinel-app
flutter pub get
flutter run                    # iOS simulator
flutter run -d chrome          # Web
flutter run -d <android-id>    # Android

# Server (optional, for remote mode)
cd packages/sentinel-server && npm install && npm run dev
```

## Current State (as of 2026-04-08)

- sentinel-cli: **17 commands**, production-ready
- sentinel-server: functional, PGlite embedded DB
- SwiftUI app: functional on Simulator, 31 Swift files
- Flutter app: **not yet started** — this CLAUDE.md is the blueprint
- Total commits: 22, total LoC: ~5000

## Decision Log

| Date | Decision | Reason |
|------|----------|--------|
| 2026-04-08 | SwiftUI → Flutter | Cross-platform (Android + Web), faster iteration |
| 2026-04-08 | PGlite over PostgreSQL | Zero external deps, single binary |
| 2026-04-08 | libsodium over CryptoKit | Cross-platform E2EE, same algo on CLI + app |
| 2026-04-08 | Riverpod over BLoC | Less boilerplate, better testability |
| 2026-04-08 | 3-tab layout | Reduced from 5, cleaner UX |
| 2026-04-08 | LAN-first design | Privacy + speed, no cloud dependency |
