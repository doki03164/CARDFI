# CardFi

Cardano-native lending, yield-bearing ADA collateral, atomic flash execution and programmable vault hooks.

## What is implemented

- Responsive CardFi Web dApp MVP
- Interactive supply, borrow and flash-execution flows
- Market utilization, LTV, health-factor and flash-fee calculations
- Wallet-connected and disconnected position states
- Aiken market, position, oracle and governance validators
- Atomic debt synchronization, bounded liquidation and governed Oracle key rotation
- Reproducible Plutus V3 blueprint and GitHub CI
- Deterministic Preprod parameterization manifest
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
npm.cmd run contracts:check
npm.cmd run contracts:build
npm.cmd run deploy:manifest:check
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
deploy/               Deterministic Preprod parameterization manifest
scripts/              Blueprint and deployment artifact tooling
infra/stake-pool/      CardFi SPO topology, services, metadata and runbook
docs/ARCHITECTURE.md  System design and production boundary
CardFi_*.md           Whitepaper, pitch and Catalyst copy
```

## Current stage

This is a testnet-oriented MVP. Four Plutus V3 validators compile reproducibly to `contracts/plutus.json`; the generated Preprod manifest binds their hashes and parameter schemas to that blueprint. Preprod submission, transaction-level integration testing, delayed/multisig governance, external audit and guarded-launch controls remain release gates.
