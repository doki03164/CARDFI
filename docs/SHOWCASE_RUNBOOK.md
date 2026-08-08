# CardFi Interactive Showcase Runbook

> The showcase supports Traditional Chinese and English. Use the `EN / 繁中` control in the header. The complete English whitepaper, pitch deck, and Catalyst proposal are available at `CardFi_Light_Whitepaper_Pitch_Deck_Catalyst_Proposal_EN.md`.

## Start and verify

```powershell
npm.cmd install
npm.cmd test
npm.cmd run build
npm.cmd run dev -- --host 127.0.0.1 --port 5173
```

Open `http://127.0.0.1:5173/`. The showcase uses deterministic demo market data and does not submit transactions to Cardano.

## Recommended 7-minute demonstration

1. **Overview (60s):** explain supplied liquidity, utilization, position health and the separation between lending collateral and native ADA delegation.
2. **Markets (60s):** open `市場`, compare ADA/DJED/iUSD/MIN, select Supply or Borrow, enter an amount and show the deterministic simulation receipt.
3. **Position (45s):** connect the Demo Wallet and show health factor, available borrowing capacity and yield-bearing ADA collateral.
4. **Flash Lab (75s):** show the four atomic stages, simulate an ADA flash route and explain that the validator requires principal plus fee in the unique continuing market output.
5. **ADA native staking (60s):** open `ADA 鏈上質押`, show `[CFI]` operator status and simulate stake registration/delegation certificates. Emphasize that ADA remains spendable in the wallet.
6. **Vault Hooks (45s):** present leveraged farming, self-repaying loans and liquidation shield as bounded composability modules.
7. **Governance and proof (90s):** show governed risk values and four compiled validator hashes, then open GitHub Actions to demonstrate reproducible Aiken, Web and deployment-manifest verification.

## Evidence links

- Repository: `https://github.com/doki03164/CARDFI`
- Contract blueprint: `contracts/plutus.json`
- Preprod parameterization manifest: `deploy/preprod.manifest.json`
- Whitepaper, pitch outline and Catalyst copy: `CardFi_Light_Whitepaper_Pitch_Deck_Catalyst_Proposal_zh-TW.md`

## Claims boundary

- `COMPILED` means the Plutus V3 validator is present in the reproducible CIP-57 blueprint.
- `Demo` and `sim_...` identifiers are local deterministic simulations, not Cardano transaction IDs.
- `[CFI]` is configuration-ready; pool registration, relay provisioning and block production are separate deployment milestones.
- Static TVL, APY, volume and position values are presentation fixtures until an indexer supplies verifiable network data.
