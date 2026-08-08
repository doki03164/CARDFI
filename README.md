# CardFi

Cardano-native lending, yield-bearing ADA collateral, atomic flash execution and programmable vault hooks.

## What is implemented

- Responsive CardFi Web dApp MVP
- Interactive supply, borrow and flash-execution flows
- Market utilization, LTV, health-factor and flash-fee calculations
- Wallet-connected and disconnected position states
- Aiken market validator skeleton with core arithmetic invariants
- CardFi-operated `[CFI]` stake-pool topology, systemd and registration templates
- CIP-30 wallet discovery and connection adapter
- Unit tests for protocol math
- Light whitepaper, 10-slide pitch outline and Catalyst proposal

## Run locally

```powershell
npm.cmd install
npm.cmd run dev
```

Open `http://127.0.0.1:5173`.

## Verify

```powershell
npm.cmd test
npm.cmd run build
```

For contracts, install Aiken and run:

```powershell
Set-Location contracts
aiken check
aiken build
```

## Repository layout

```text
src/                  React Web dApp and protocol math
contracts/            Aiken contract project
infra/stake-pool/      CardFi SPO topology, services, metadata and runbook
docs/ARCHITECTURE.md  System design and production boundary
CardFi_*.md           Whitepaper, pitch and Catalyst copy
```

## Current stage

This is a testnet-oriented MVP. Mainnet release requires completed value-level validators, wallet SDK integration, independent oracle inputs, external audits, reproducible builds and a guarded-launch risk process.
