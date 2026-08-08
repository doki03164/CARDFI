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

## Current compiled validator

- Blueprint title: `market.market.spend`
- Plutus version: `v3`
- Market hash: `9c46b65ba31ab3d6ebc72daad128d2ad92dd0d3de848b93a91cab90a` — 3,149 bytes
- Oracle hash: `fd590b7ba645b3cbe6524e12a528d1cb1507a3da28144da4c3a4191f` — 1,715 bytes
- Position hash: `c8c7a05d3bd83150ffc533b578b022cb7c4f869c531836a5ce195d8c` — 1,060 bytes

The hash changes whenever the validator or compiler output changes. CI rebuilds the blueprint on every push.

## Mainnet gates still required

Before Preprod deployment it must still add atomic market-position debt synchronization, liquidation close-factor logic, governance parameter bindings, publisher key rotation and full transaction-level scenario tests.
