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
- exact opposite market-asset movement for borrow and repay

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

## Current compiled validator

- Blueprint title: `market.market.spend`
- Plutus version: `v3`
- Market hash: `4a869d3a7272621dac3ff33df49cd6b2d827698004d663504a476f5c` — 4,159 bytes
- Oracle hash: `fd590b7ba645b3cbe6524e12a528d1cb1507a3da28144da4c3a4191f` — 1,715 bytes
- Position hash: `1322346597bb3f2fd937682ea6eac9581958dc13ae9548739425db8b` — 1,612 bytes

The hash changes whenever the validator or compiler output changes. CI rebuilds the blueprint on every push.

## Mainnet gates still required

Before Preprod deployment it must still add liquidation close-factor logic, governance parameter bindings, publisher key rotation and full transaction-level scenario tests.
