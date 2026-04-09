# CLAUDE.md — Sentinel Project Guide

## Project Identity

**Name:** Sentinel  
**Tagline:** The security gate between AI agents and your system  

## Architecture

```
Claude Code ──hooks──→ sentinel-cli ──TCP/WS──→ iOS App (SwiftUI)
                        :7749/:7750
```

## Stack

| Layer | Technology |
|-------|-----------|
| iOS App | Swift 5.9 + SwiftUI + iOS 17+ |
| CLI | Node.js 20 + TypeScript |
| LAN | TCP + Bonjour/mDNS |

## Structure

```
Sentinel/              # SwiftUI iOS App
  Views/               # TerminalView, HistoryView, SettingsView, etc.
  Models/              # ApprovalRequest, ActivityItem, TimelineEntry, etc.
  Network/             # ApprovalStore, RelayService
  Transport/           # LocalTransport, ServerTransport, CloudKitTransport
  Services/            # BiometricService, TrustManager, SuggestionEngine, etc.
  Crypto/              # IdentityManager, TransportEncryption
  Components/          # InlineApprovalCard, InlineSummaryCard, DiffView, etc.
  Helpers/             # ApprovalHelper, SharedStateWriter, SentinelConfig

SentinelWidget/        # iOS Widget Extension

packages/
  sentinel-cli/        # Mac CLI (17+ commands)
```

## Rules

1. NEVER introduce third-party cloud services
2. NEVER transmit unencrypted user data
3. NEVER auto-approve without user consent
4. NEVER send file contents through push notifications
