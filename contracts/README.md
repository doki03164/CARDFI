# CardFi Aiken Contracts

Pinned toolchain: Aiken `v1.1.23`, Plutus `v3`, stdlib `v3.0.0`.

## Validators

The current `market.market.spend` validator implements transaction-bound transition gates for:

- supply and available-liquidity withdrawal
- over-collateralized borrow with LTV basis points
- debt repayment bounds
- atomic flash principal availability and fee repayment
- a unique continuing output at the same script address
- shard identity NFT preservation
- exact market-asset value delta for every action
- exact datum transition with monotonic nonce
- non-negative, non-insolvent market state constraints
- oracle NFT reference input, finite price validity window and rational LTV check
- borrow/repay binding to exactly one consumed and recreated position NFT
- position-owner signature and exact debt/nonce synchronization
- immutable maximum-LTV parameter enforced above the borrow redeemer value
- permissionless liquidation for positions below the oracle-priced threshold
- close-factor limit and exact liquidation-bonus collateral seizure ceiling

The `oracle.oracle.spend` validator adds a publisher-signed oracle state thread with:

- unique oracle NFT preservation
- exact sequence increment
- positive rational price
- monotonically advancing validity window
- transaction validity range containment

The `position.position.spend` validator adds the ownership layer with:

- owner verification-key signature
- unique position NFT and continuing output
- exact collateral asset delta
- immutable owner and monotonic nonce
- non-negative collateral and debt state
- non-zero debt adjustment bound to exactly one market shard transition
- exact opposite market-asset movement for borrow, repay and liquidation
- permissionless liquidation independently checked against the oracle and fixed risk parameters

The generated CIP-57 blueprint is committed as `plutus.json` so off-chain transaction builders can consume its schema and compiled code.

## Reproduce

```powershell
npm.cmd run contracts:check
npm.cmd run contracts:build
```

Expected tests include:

- exact supply transition
- rejection of insolvent state
- valid and over-LTV borrow cases
- atomic flash fee/reserve transition
- exact market-position borrow and repay synchronization
- rejection of debt changes without matching market asset movement
- valid under-collateralized partial liquidation
- rejection of healthy, stale-price, over-close-factor and excessive-seizure liquidations

## Current compiled validator

- Blueprint title: `market.market.spend`
- Plutus version: `v3`
- Market hash: `c1c09d29a0a0d188131f8ac375a4700b56fe70f4a77de43a5dcbab12` — 5,385 bytes
- Oracle hash: `fd590b7ba645b3cbe6524e12a528d1cb1507a3da28144da4c3a4191f` — 1,715 bytes
- Position hash: `baa8bfb448f6e2830917d5eb09be628a7f274859cbbca42fd42c6b21` — 3,233 bytes

The hash changes whenever the validator or compiler output changes. CI rebuilds the blueprint on every push.

## Mainnet gates still required

Before Preprod deployment it must still add a governance state thread for controlled parameter upgrades, publisher key rotation and full transaction-level scenario tests.
