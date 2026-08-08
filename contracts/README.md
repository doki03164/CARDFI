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
- publisher authorization resolved from the current Governance NFT datum

The `governance.governance.spend` validator adds a protocol configuration state thread with:

- unique Governance NFT preservation and monotonic sequence
- bounded LTV, liquidation threshold, close factor and bonus parameters
- admin-signed risk and Oracle publisher updates
- two-key acceptance for admin rotation
- prevention of hidden risk changes during admin rotation

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
- governed risk-parameter and Oracle publisher updates
- rejection of invalid risk ordering and mixed admin/risk rotation

## Current compiled validator

- Blueprint title: `market.market.spend`
- Plutus version: `v3`
- Governance hash: `64b0d65a071a3d58052fec7dd569846c43dc4a81d53ad5822010de31` — 1,380 bytes
- Market hash: `14c01b4906bbd2c76667d333a9d462ba859b3728651b4c315a413200` — 5,613 bytes
- Oracle hash: `6651fbd68f654ba2eed21d6d19dceffcdf73f9930bb42bd93cf2a73f` — 1,926 bytes
- Position hash: `1aa0889691276922f22c9dda9c7063da2f322ef4bfd4a3d4a8957f32` — 3,453 bytes

The hash changes whenever the validator or compiler output changes. CI rebuilds the blueprint on every push.

## Mainnet gates still required

Before Preprod deployment it must still add delayed governance activation/multisig policy, full transaction-level scenario tests and deployment manifests.
