# CardFi Aiken Contracts

Pinned toolchain: Aiken `v1.1.23`, Plutus `v3`, stdlib `v3.0.0`.

## Validators

The current `market.market.spend` validator implements the first arithmetic transition gates for:

- supply and available-liquidity withdrawal
- over-collateralized borrow with LTV basis points
- debt repayment bounds
- atomic flash principal availability and fee repayment

The generated CIP-57 blueprint is committed as `plutus.json` so off-chain transaction builders can consume its schema and compiled code.

## Reproduce

```powershell
npm.cmd run contracts:check
npm.cmd run contracts:build
```

Expected tests:

- `flash_fee_invariant` passes for a correctly paid 7 bps fee.
- `underpaid_flash_fee_fails` succeeds only when the underpayment path crashes as expected.

## Current compiled validator

- Blueprint title: `market.market.spend`
- Plutus version: `v3`
- Script hash: `28c4483445459b63b8e7a4520c7483c4c0c82f7ba11cebf8e6beffd5`
- Compiled code size: 722 bytes

The hash changes whenever the validator or compiler output changes. CI rebuilds the blueprint on every push.

## Mainnet gates still required

The current validator intentionally isolates arithmetic logic. Before Preprod deployment it must add shard identity NFT forwarding, exact value conservation, oracle freshness, output datum transition, position ownership, liquidation and governance parameter bindings.
