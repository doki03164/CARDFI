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
- Script hash: `def182ce7592ceba1fb17eea6983b9389698a5e8d1b15e289285655f`
- Compiled code size: 2,026 bytes

The hash changes whenever the validator or compiler output changes. CI rebuilds the blueprint on every push.

## Mainnet gates still required

Before Preprod deployment it must still add independent oracle freshness/signature checks, position ownership, liquidation close-factor logic, governance parameter bindings and full transaction-level scenario tests.
