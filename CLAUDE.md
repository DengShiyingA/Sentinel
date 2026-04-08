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
| Server | Fastify + Socket.IO + PGlite |
| LAN | TCP + Bonjour/mDNS |

## Structure

```
Sentinel/              # SwiftUI iOS App
  Views/               # 10 screens
  Models/              # ApprovalRequest, ActivityItem, ConnectionMode, Rule
  Network/             # ApprovalStore, RelayService, LocalDiscoveryService, SocketClient
  Transport/           # LocalTransport, ServerTransport, CloudKitTransport
  Services/            # PairingService, BiometricService, NotificationService
  Crypto/              # IdentityManager, TransportEncryption
  Components/          # ToolIcon, RiskBadge, CountdownRing, TerminalLine
  Helpers/             # KeychainHelper

packages/
  sentinel-cli/        # Mac CLI (17+ commands)
  sentinel-server/     # Relay server (optional)
```

## Rules

1. NEVER introduce third-party cloud services
2. NEVER transmit unencrypted user data
3. NEVER auto-approve without user consent
4. NEVER send file contents through push notifications
