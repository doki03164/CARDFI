# CardFi Light Whitepaper, Pitch Deck and Project Catalyst Proposal

**Version:** v1.0 English Draft  
**Date:** 8 August 2026  
**Language:** English

> **Disclosure.** “The first in the Cardano ecosystem” is a positioning statement that requires a final competitive and legal review before public use. APY, LTV, fees, token allocations, market data and budgets in this document are design assumptions rather than guaranteed returns, investment advice or final governance parameters. The current public repository is an interactive testnet-oriented prototype; simulated transaction identifiers are not Cardano transaction IDs.

---

# Module 1 — CardFi Light Whitepaper

## 1. Executive Summary

CardFi is a non-custodial lending and liquidity protocol for Cardano native assets. It brings five capabilities into one product layer: over-collateralized lending, productive ADA collateral, atomic flash execution, programmable Smart Vault Hooks, and a unified native wallet plus Web dApp experience.

CardFi treats “staking” as two separate products:

1. **Lending collateral.** ADA is spent into CardFi script UTxOs and used to establish borrowing capacity. A production design may associate script-held ADA with a controlled staking credential and account for rewards without weakening borrower, supplier or protocol rights.
2. **Native Cardano delegation.** ADA remains spendable in the user’s wallet. The wallet signs stake-address registration and delegation certificates for the CardFi-operated `[CFI]` stake pool. Principal is not deposited into CardFi, there is no protocol lockup, and rewards are calculated by the Cardano ledger according to epoch and pool performance.

CardFi does not run EVM bytecode on Cardano. It recreates advanced DeFi behavior with Aiken validators, eUTXO state, reference inputs and whole-transaction atomicity. The initial market set targets ADA, DJED, iUSD and governance-approved Cardano Native Tokens.

The core value proposition is:

- **Capital efficiency:** ADA collateral can remain economically productive while backing credit, subject to transparent staking accounting and risk controls.
- **Composable finance:** flash execution and bounded hooks support arbitrage, rebalancing, liquidation, leveraged strategies and yield-directed debt repayment.
- **Predictable execution:** complete eUTXO inputs and outputs are constructed before submission, reducing uncertainty caused by globally mutable state.
- **Accessible product experience:** the wallet and Web dApp expose simulation, health factor, batch signing, staking delegation and human-readable risk warnings.

Protocol revenue can come from a reserve share of borrowing interest, flash-execution fees, liquidation revenue sharing and premium vault services. Every economic parameter is intended to be governed within explicit on-chain bounds and change controls.

## 2. Market Problem and the Cardano–EVM Opportunity

### 2.1 Market gaps

Cardano liquidity is distributed across DEXs, stablecoins, staking and lending products. Moving between these products often requires multiple transactions, repeated signatures and manual risk management. ADA holders also face an opportunity cost when a collateral design prevents them from receiving native staking rewards.

The ecosystem has room for standardized composability interfaces, reusable flash liquidity, liquidation SDKs and transaction-building infrastructure. At the same time, eUTXO parallelism is not automatic: a design that routes every operation through one pool UTxO produces contention, retries and a poor user experience.

### 2.2 What CardFi learns from Aave

Aave demonstrates the strength of shared liquidity, over-collateralization, utilization-driven interest rates, health-factor monitoring, permissionless liquidation, flash liquidity and governed risk parameters. EVM atomic composability also enables one transaction to combine lending, swaps and yield strategies.

Its broader execution environment nevertheless highlights common constraints: volatile execution costs during congestion; public-ordering competition and extractable value; and integration risk created by callbacks, approvals, reentrancy and shared mutable state.

### 2.3 CardFi’s synthesis

- **Aiken validators:** strongly typed, functional validation logic compiled to Plutus V3 and covered by deterministic tests.
- **Local state shards:** each market can be divided across identity-NFT liquidity shard UTxOs rather than one global state object.
- **Atomic settlement:** flash execution consumes a market input and must recreate the unique valid continuing output with principal and fee accounted for, otherwise the complete transaction fails.
- **Reduced MEV surface:** explicit inputs, outputs, validity intervals, slippage limits and restricted hooks reduce arbitrary execution paths. CardFi does not claim to eliminate all MEV; Oracle timing, batcher ordering, liquidation competition and cross-DEX routing still create extractable value.
- **EVM-familiar developer interface:** supply, withdraw, borrow, repay, liquidate, flashExecute and hook concepts map to transaction-builder calls, datum and redeemers rather than pretending that Cardano offers synchronous EVM callbacks.

## 3. CardFi Protocol Architecture

### 3.1 On-chain and off-chain components

| Component | Responsibility | Principal control |
|---|---|---|
| Governance State | Risk values and authorized Oracle publisher | Governance NFT, admin signatures, sequence |
| Liquidity Shards | Assets and market accounting | Shard NFT, value conservation, unique continuation |
| Position UTxOs | Owner, collateral, debt and nonce | Position NFT, owner signature, market synchronization |
| Oracle State | Rational price and validity window | Oracle NFT, governed publisher, monotonic sequence |
| Flash Executor | Atomic liquidity and repayment | Same-transaction principal and fee validation |
| Stake Controller | Delegation and reward attribution | Stake credentials, multisig and epoch accounting |
| Batcher / Solver | Intent aggregation and shard selection | Permissionless participation, bond and fallback paths |
| Indexer | Markets, positions, events and proof APIs | Reproducible chain-derived state |

### 3.2 Liquidity, LTV and interest rates

Suppliers deposit assets into a market shard and receive accounting shares or a policy-controlled receipt asset. Borrowers lock collateral in a position UTxO and create debt shares. Index-based accounting avoids continuous per-account updates.

For a market:

- `U = TotalBorrows / (AvailableLiquidity + TotalBorrows − Reserves)`
- Below target utilization: `BorrowAPR = Base + Slope1 × U / U_opt`
- Above target utilization: `BorrowAPR = Base + Slope1 + Slope2 × (U − U_opt) / (1 − U_opt)`
- `SupplyAPR ≈ BorrowAPR × U × (1 − ReserveFactor)`

Borrow validation uses a fresh Oracle reference input and an exact rational inequality rather than floating-point division:

`Debt × 10,000 × PriceDenominator ≤ Collateral × PriceNumerator × LTV_bps`

The user-supplied LTV cannot exceed the maximum value in the Governance NFT datum.

### 3.3 Productive ADA collateral

ADA locked in a script UTxO can be associated with a staking credential, but reward rights and accounting must be explicit. CardFi’s production design separates principal, accrued rewards, withdrawal authority and protocol fees. Users see lending yield and native PoS yield as distinct components. A pool operator cannot spend lending collateral, and the lending contract cannot silently redirect wallet delegation.

CardFi also operates a separate `[CFI]` stake pool infrastructure domain: block producer, relays, KES and VRF lifecycle, pledge, metadata and monitoring. Wallet delegation to `[CFI]` is non-custodial and is not treated as a deposit into the lending protocol.

### 3.4 Atomic flash execution

A flash transaction consumes a market shard, temporarily routes liquidity through approved operations and recreates the shard output in the same Cardano transaction. Validation binds:

- the shard identity NFT;
- the unique continuing script output;
- the exact datum transition and monotonic nonce;
- the exact market-asset delta;
- available-liquidity limits; and
- a minimum fee in basis points.

No persistent unsecured debt is created. Failure at any point invalidates the entire transaction.

### 3.5 Smart Vault Hooks

Hooks allow approved third-party scripts to compose with CardFi without arbitrary callbacks. A production hook registry binds script hashes, asset allowlists, maximum slippage, expiry, execution caps and emergency disable controls.

Initial use cases are:

1. **Leveraged Farming:** supply, borrow, swap and add liquidity through one bounded route.
2. **Self-Repaying Loans:** periodically direct PoS or strategy yield toward debt reduction.
3. **Liquidation Shield:** execute bounded deleveraging as a position approaches its liquidation threshold.

### 3.6 Market–position synchronization

Borrow and repay actions consume and recreate one named Position NFT and one Market Shard NFT. Both validators independently check the same debt delta, nonce increment and opposite market-asset movement. This prevents a market balance change from being detached from the borrower’s position state.

### 3.7 Wallet and Web dApp

The Web dApp and future extension/mobile wallet share transaction-building and risk libraries. The experience includes:

- CIP-30 wallet discovery and connection;
- transaction simulation before signing;
- supply, borrow, repay, flash and delegation workflows;
- health factor and liquidation-price warnings;
- deterministic failure explanations; and
- links to script hashes, parameters and transaction evidence.

## 4. Security, Liquidation and Flash Execution

### 4.1 Security model

CardFi applies defense in depth:

- unique identity NFTs for Governance, Oracle, Market Shards and Positions;
- inline datum schemas and exact continuing-output rules;
- rational arithmetic and finite Oracle validity windows;
- owner signatures for voluntary position changes;
- governed Oracle publisher authorization and key rotation;
- two-key acceptance when rotating the governance administrator;
- non-negative and solvency-shaped state invariants;
- transaction validity intervals and replay-resistant nonces;
- CI-reproducible CIP-57 blueprint and deployment manifest; and
- external audit, property testing, fuzzing and execution-budget measurement before a guarded mainnet launch.

### 4.2 Liquidation

A position becomes liquidatable only when Oracle-priced debt is strictly above the governed collateral threshold:

`Debt × 10,000 × PriceDenominator > Collateral × PriceNumerator × LiquidationThreshold_bps`

Liquidation is permissionless, but repayment is capped by the governed close factor. Seized collateral cannot exceed the value of repaid debt plus the governed bonus:

`SeizedCollateral × PriceNumerator × 10,000 ≤ RepaidDebt × PriceDenominator × (10,000 + Bonus_bps)`

The Market and Position validators both verify Oracle freshness, debt reduction, collateral reduction, market repayment and the next nonce. A same-transaction DEX spot price is never accepted as the sole liquidation Oracle.

### 4.3 Governance safety

The current compiled prototype stores maximum LTV, liquidation threshold, close factor, bonus and Oracle publisher in a Governance NFT datum. Production readiness additionally requires delayed activation, multisig or committee policy, emergency roles with narrow permissions, parameter-change monitoring and a public governance interface.

## 5. Tokenomics and Governance

The protocol can initially launch without making a transferable token necessary for core lending. If a `CARDFI` governance token is introduced, utility should be limited to genuine governance, risk backstop participation, fee-policy voting and contributor alignment rather than guaranteed yield.

An illustrative allocation is:

| Allocation | Share | Control |
|---|---:|---|
| Community and ecosystem | 35% | Multi-year emissions and grants |
| Protocol treasury | 25% | Timelock and public reporting |
| Team and future hires | 20% | Cliff plus long vesting |
| Strategic contributors | 10% | Milestone-based vesting |
| Security and risk reserve | 10% | Restricted backstop mandate |

No final allocation, valuation or issuance schedule should be published before legal, tax, governance and market-structure review.

Governance evolves through four stages: founding multisig; multisig plus public timelock; delegated token or representative governance with a risk council; and mature on-chain governance with transparent upgrade and emergency processes.

## 6. Roadmap

### Phase 1 — Compiled MVP

- Interactive Web showcase and CIP-30 discovery.
- Aiken Governance, Market, Oracle and Position validators.
- Atomic supply, withdraw, borrow, repay, flash and liquidation invariants.
- Reproducible CIP-57 blueprint, CI and Preprod parameterization manifest.
- `[CFI]` stake-pool infrastructure templates.

### Phase 2 — Public Preprod

- Production transaction builder, indexer, batcher and Oracle feeder.
- Parameterized validator deployment and published transaction evidence.
- End-to-end transaction scenarios and execution-budget benchmarks.
- Wallet signing, submission and confirmation tracking.

### Phase 3 — Audit and Composability

- Smart Vault Hooks registry and SDK.
- External security audit and public remediation report.
- Delayed/multisig governance and monitoring.
- `[CFI]` stake-pool node provisioning and registration.

### Phase 4 — Guarded Mainnet

- Isolated initial markets with caps and conservative parameters.
- Bug bounty, incident response and real-time solvency monitoring.
- Progressive asset onboarding, liquidity partnerships and decentralized batchers.
- Governance decentralization based on verified operations.

---

# Module 2 — 10-Slide Pitch Deck Outline

## Slide 1 — CardFi: Productive Liquidity on Cardano

**Visual:** ADA collateral flowing simultaneously into credit capacity and transparent PoS reward accounting.  
**Key points:** Cardano-native lending; atomic flash execution; programmable vaults; native wallet and Web experience; separate CardFi-operated `[CFI]` stake pool.

## Slide 2 — The Problem

**Visual:** fragmented DEX, lending, stablecoin and staking islands.  
**Key points:** repeated signatures and fragmented liquidity; opportunity cost of idle ADA collateral; limited reusable flash liquidity and liquidation tooling; eUTXO contention when protocols use one global state UTxO.

## Slide 3 — The CardFi Solution

**Visual:** four-layer product stack: Market, Productive ADA, Flash/Hooks, Wallet.  
**Key points:** one non-custodial product for supply and borrowing; governed Oracle risk; atomic execution; user-friendly simulation; native wallet delegation to the CardFi-operated pool.

## Slide 4 — Advanced Smart Contract Features

**Visual:** one atomic transaction with market input, strategy operations and continuing output.  
**Key points:** zero-collateral flash execution; leveraged farming; self-repaying loans; liquidation shield; permissionless bounded liquidation; exact value conservation.

## Slide 5 — Product Matrix

**Visual:** side-by-side Web dApp and wallet flows.  
**Key points:** Web for market discovery, positions, governance and analytics; wallet for signing, simulation, alerts and delegation; shared transaction-builder and risk SDK.

## Slide 6 — Technical Advantage

**Visual:** Aiken validators connected by Governance, Oracle, Shard and Position NFTs.  
**Key points:** Plutus V3; eUTXO determinism; shard concurrency; rational Oracle arithmetic; atomic market–position debt synchronization; reproducible blueprint and CI.

## Slide 7 — Market and Business Model

**Visual:** revenue flywheel from liquidity to borrowing, flash volume and premium vaults.  
**Key points:** reserve factor; flash fees; liquidation revenue share; premium vault services; SPO margin as a separate infrastructure revenue line; no reliance on guaranteed token appreciation.

## Slide 8 — Roadmap and Proof

**Visual:** four phases with GitHub evidence under each.  
**Key points:** compiled MVP complete; Preprod integration next; audit and hooks; guarded mainnet. Show current validator hashes, 27 Aiken tests, Web tests and CI status.

## Slide 9 — Team and Advisors

**Visual:** verified team cards.  
**Placeholders:** `[FOUNDER_NAME]`, `[AIKEN_ENGINEER]`, `[OFFCHAIN_ENGINEER]`, `[SPO_ENGINEER]`, `[RISK_ADVISOR]`, `[AUDIT_PARTNER]`. Include GitHub, LinkedIn, delivery history and committed availability.

## Slide 10 — Ask and Contact

**Visual:** six-month use-of-funds bar and QR links to repository and showcase.  
**Ask:** 180,000 ADA reference budget for transaction infrastructure, Preprod, Vault Hooks, audit, SPO deployment and public beta. Final amount depends on the rules of the next active funding round.  
**Contact placeholders:** `[WEBSITE]`, `[EMAIL]`, `[X]`, `[DISCORD]`.

---

# Module 3 — Project Catalyst Proposal Draft

## 1. Project Title and Elevator Pitch

**Title:** CardFi — Yield-Bearing Lending, Atomic Flash Execution and Native ADA Staking Infrastructure

**Elevator Pitch:**

CardFi is building a Cardano-native, non-custodial lending and liquidity protocol that combines over-collateralized credit, productive ADA collateral, atomic flash execution, programmable Smart Vault Hooks and a unified wallet plus Web dApp. Its Aiken/Plutus V3 prototype already compiles four validators for governance, markets, Oracles and positions. The contracts enforce unique state NFTs, fresh rational prices, market–position debt synchronization, flash fees, bounded liquidation and governed Oracle key rotation. CardFi also clearly separates lending collateral from native wallet delegation to the CardFi-operated `[CFI]` stake pool. Funding will convert this compiled and interactive MVP into a public Preprod product with real transaction construction, indexing, batcher services, Oracle feeds, Vault Hooks, third-party audit, SPO infrastructure and measurable on-chain evidence.

## 2. Problem and Solution

Cardano users must navigate fragmented lending, stablecoin, DEX and staking experiences. Advanced liquidity primitives remain harder to integrate than familiar EVM interfaces, while naïve eUTXO designs create contention around shared state.

CardFi addresses this with sharded liquidity UTxOs, identity NFTs, Aiken validators and a transaction-builder SDK. Users can supply assets, create collateralized positions, borrow, repay, execute flash liquidity and monitor liquidation risk. Developers receive bounded hook interfaces for atomic strategies. ADA users also receive a separate, non-custodial delegation flow to a CardFi-operated native stake pool.

## 3. Impact on Cardano

CardFi creates directly measurable Cardano activity across supply, withdrawal, borrowing, repayment, liquidation, flash execution, Oracle update, governance update and stake delegation transactions. A familiar SDK lowers the learning cost for EVM developers while preserving Cardano’s actual eUTXO semantics.

The protocol can attract arbitrageurs and liquidation agents because flash liquidity removes the need to pre-fund every route. This increases DEX interaction and price alignment, while deterministic limits reduce unbounded callback risk. Public validators, SDKs and transaction examples also provide reusable infrastructure for the wider ecosystem.

Target KPIs for the funded six-month scope are:

- four parameterized validators deployed to Preprod;
- at least five complete transaction families demonstrated on-chain;
- 99% deterministic scenario-test pass rate in CI;
- 100 developer SDK downloads or repository clones/stars as an initial engagement signal;
- 30 external test wallets and 500 successful Preprod transactions;
- three documented Vault Hook examples;
- one independent audit and public remediation report;
- public `[CFI]` node and registration evidence appropriate to the selected network.

## 4. Feasibility and Risk Mitigation

The project is past the idea stage. The repository contains an interactive bilingual showcase, four compiled Plutus V3 validators, 27 Aiken tests, CIP-30 discovery, a deterministic CIP-57 blueprint, a Preprod manifest, stake-pool infrastructure templates, architecture documentation and GitHub Actions verification.

Principal risks and mitigations are:

| Risk | Mitigation |
|---|---|
| Contract defect | Independent audit, property tests, capped launch and bug bounty |
| Oracle failure | Governed publisher, finite validity, sequence, deviation monitoring and future multi-source aggregation |
| UTxO contention | Shards, batcher selection, retry policy and permissionless fallback |
| Governance compromise | Delayed activation, multisig, narrow emergency roles and public monitoring |
| Liquidity shortage | Conservative initial markets, caps and staged partnerships |
| SPO operational failure | Redundant relays, KES monitoring, offline keys and documented rotation |
| Delivery risk | Public milestones, reproducible commands, CI and milestone-linked payments |

Team placeholders must be replaced with verifiable identities, repositories, portfolios, availability and disclosed roles before submission.

## 5. Six-Month Milestones and Proof of Achievement

### Milestone 1 — Transaction Infrastructure (Months 1–2)

**Deliverables:** Supply, withdraw, borrow, repay, flash and liquidation transaction builders; indexer schema; shard-selection service.  
**Proof:** public code, CI, fixed test vectors, reproducible commands and successful/failing scenario records.

### Milestone 2 — Preprod Protocol (Months 2–3)

**Deliverables:** parameterized validators, Governance/Oracle/Market initialization, Oracle feeder and monitoring.  
**Proof:** explorer links, script hashes, transaction IDs, manifest, configuration and operational dashboard.

### Milestone 3 — Wallet SDK and Vault Hooks (Months 3–4)

**Deliverables:** CIP-30 signing/submission, hook registry, leveraged farming, self-repayment and liquidation-shield examples.  
**Proof:** public dApp, SDK documentation, end-to-end video and Preprod transactions.

### Milestone 4 — Audit and SPO Infrastructure (Months 4–5)

**Deliverables:** independent contract audit, remediation, relay/block-producer deployment and stake-pool operational evidence.  
**Proof:** audit summary, issue-to-commit mapping, retest record and infrastructure monitoring.

### Milestone 5 — Public Beta and Close-out (Month 6)

**Deliverables:** public beta, community test program, KPI dashboard, final report and close-out video.  
**Proof:** wallet and transaction metrics, resolved issues, published report and video.

## 6. Detailed Budget

| Work package | ADA |
|---|---:|
| Transaction builder, indexer and batcher | 42,000 |
| Preprod deployment and Oracle feeder | 28,000 |
| Smart Vault Hooks and wallet SDK | 30,000 |
| Independent security audit and remediation | 45,000 |
| `[CFI]` stake-pool nodes and monitoring | 15,000 |
| Documentation, community testing, project management and reporting | 20,000 |
| **Total** | **180,000** |

This budget funds future delivery only. Existing code, design and documentation are prior team contributions and evidence of capability, not retroactive expenses. The amount must be adjusted to the category limits and rules of the next active funding round.

## 7. KPIs

- On-chain: successful transactions by action type, failure rate, unique wallets, active positions and Oracle/governance updates.
- Liquidity: supplied assets, borrowed assets, utilization and flash volume on the selected network.
- Developer adoption: SDK usage, integrations, documentation traffic and external contributors.
- Security: test coverage, vulnerabilities found and closed, audit remediation and incident metrics.
- SPO: node uptime, relay health, KES status, delegator count and blocks where applicable.
- Delivery: milestone timeliness, public Proofs of Achievement and budget variance.

---

## Current Artifact References

- Repository: https://github.com/doki03164/CARDFI
- Interactive showcase: run locally at `http://127.0.0.1:5173/`
- CIP-57 blueprint: `contracts/plutus.json`
- Preprod manifest: `deploy/preprod.manifest.json`
- Showcase runbook: `docs/SHOWCASE_RUNBOOK.md`
- Funding application guide: `docs/FUNDING_APPLICATION_GUIDE_zh-TW.md`

