# CardFi 輕量白皮書、Pitch Deck 與 Project Catalyst 提案稿

**版本：** v0.9 Draft｜**日期：** 2026-08-08｜**語言：** 繁體中文  
**定位聲明：**「Cardano 生態系首個」屬品牌定位與待驗證主張；公開發表前應完成競品檢索與法律審閱。本文所列 APY、LTV、費率、代幣配置與預算均為設計假設，不構成收益保證、投資建議或最終治理參數。

---

# 模組一｜CardFi 輕量白皮書（Light Whitepaper）

## 1. 摘要（Executive Summary）

CardFi 是面向 Cardano 原生資產的非託管借貸與流動性協議，目標是在同一產品層整合：**超額抵押借貸、ADA 原生 PoS 質押收益、原子閃電貸、可程式化 Smart Vault Hooks，以及 Native Wallet + Web dApp 雙端體驗**。

CardFi 的「質押」包含兩個彼此獨立的產品：**（A）借貸抵押品**，ADA 進入 CardFi script UTxO 並用於取得借款額度；**（B）Cardano 原生鏈上委託**，ADA 保留在使用者錢包，由 staking credential 透過註冊與 delegation certificate 委託給註冊 Stake Pool。後者不把本金存入 CardFi、沒有協議鎖倉，獎勵由 Cardano 帳本依 epoch 與池表現計算。

CardFi 並非把 EVM 位元碼搬到 Cardano，而是以 Aiken 編寫驗證器、以 eUTXO 狀態與單筆交易原子性，重建使用者熟悉的 EVM DeFi 能力。第一期市場支援 ADA、DJED、iUSD 與經治理白名單核准的 Cardano Native Tokens（CNTs）。

核心價值主張：

1. **資本效率：** 抵押 ADA 後仍可由協議控制的 staking credential 委託至 Cardano stake pool；實際年化收益隨網路與池表現變動。
2. **可組合金融：** 以 Flash Execution 與受限 Hook 介面支援套利、再平衡、清算、槓桿策略與獎勵自動償債。
3. **可預測執行：** eUTXO 交易預先建構並驗證完整輸入與輸出，可降低全域可變狀態帶來的非確定性；仍須正視 UTxO contention、排序競爭與 batcher 信任面。
4. **雙端體驗：** 錢包內建交易模擬、Health Factor、批次簽名與風險提示，Web dApp 提供完整市場、治理與開發者介面。

CardFi 將收入來源設計為借款利息中的 reserve factor、閃電貸費、清算協議分潤與進階金庫服務費；所有費率均由治理在上限、延遲與風險委員會框架內調整。

## 2. 市場痛點與 Cardano／EVM 融合契機

### 2.1 市場痛點

- Cardano DeFi 的流動性分散於 DEX、穩定幣、staking 與借貸產品，跨協議操作常需多次簽名與手動搬移資產。
- 原生 ADA 若因抵押結構或產品設計而失去 staking 收益，會形成明顯機會成本。
- 進階執行工具、標準化 composability API、清算 SDK 與可重用的 flash liquidity 仍有成長空間。
- eUTXO 的並行能力並非自動成立；若所有操作競爭單一池 UTxO，會產生 contention、失敗重試與體驗瓶頸。

### 2.2 Aave 機制的優勢與瓶頸

**可借鏡優勢：**

- 共享流動性池、超額抵押、逐資產 LTV／Liquidation Threshold／Reserve Factor。
- 以利用率驅動的動態利率，使供需可由價格訊號調節。
- Health Factor、permissionless liquidation、flash liquidity 與治理風險參數，形成完整貨幣市場工具箱。
- EVM 原子可組合性讓單筆交易能跨 DEX、借貸與收益協議完成複合策略。

**典型瓶頸：**

- 高需求時鏈上執行成本與 gas price 競價可能抬升小額操作門檻。
- 公開 mempool、交易排序與 priority fee 競爭可形成 sandwich、front-running 與清算競賽。
- 共享可變合約狀態、跨合約 callback 與 token approval 增加重入、授權及整合複雜度。

### 2.3 CardFi 的融合策略

- **Aiken 驗證器：** 強型別、純函數式驗證邏輯，編譯至 UPLC；搭配單元測試、屬性測試、模糊測試與執行成本基準。
- **局部狀態分片：** 每個資產市場分為多個 liquidity shard UTxO；order UTxO 與 position UTxO 分離，避免單一全域 UTxO。
- **原子結算：** 閃電貸交易必須在同一筆交易中消耗池輸入並重建合法池輸出，且輸出資產不少於本金、費用與保留值，否則整筆交易失敗。
- **降低 MEV 面：** 交易輸入／輸出與有效區間預先固定，限制任意 callback；可選 commit-reveal intent、批次撮合、slippage bound 與短 validity interval。CardFi 不宣稱消除所有 MEV：oracle 更新、batcher 排序、清算競爭及跨 DEX 路由仍可能產生可擷取價值。
- **EVM 開發者入口：** 提供概念對照 SDK（supply、withdraw、borrow、repay、flashExecute、liquidate、hook），但底層採交易建構器與 datum/redeemer，而非假裝具備同步 EVM callback。

## 3. 核心協議架構（CardFi Protocol Architecture）

### 3.1 合約與鏈下元件

| 元件 | 職責 | 關鍵控制 |
|---|---|---|
| Market Registry | 市場白名單、參數版本、script hash | Governance NFT、timelock |
| Liquidity Shards | 持有資產、記錄 supply/borrow index | shard NFT、value conservation |
| Position UTxO | 抵押品、債務 shares、owner credential | owner signature、HF 檢查 |
| Oracle Adapter | 聚合價格與時間戳 | 多源中位數、staleness、deviation cap |
| Flash Executor | 原子借出與歸還驗證 | 同交易還本付費、hook allowlist |
| Stake Controller | ADA 委託、獎勵提領與分配 | staking script／多簽、epoch accounting |
| Batcher／Solver Network | 聚合 intents、選 shard、建構交易 | permissionless bond、SLA、fallback |
| Risk & Governance | 參數變更、pause、資產上架 | timelock、caps、角色分權 |

### 3.2 流動性池、LTV 與動態利率

供應者存入資產後取得不可轉讓的供應 shares 或受政策控制的 receipt token；借款人以 position UTxO 鎖定抵押並鑄造 debt shares。指數化會計避免逐帳戶持續更新：

- `Utilization U = TotalBorrows / AvailableLiquidity+TotalBorrows−Reserves`
- 當 `U ≤ U_opt`：`BorrowAPR = R_base + S1 × U/U_opt`
- 當 `U > U_opt`：`BorrowAPR = R_base + S1 + S2 × (U−U_opt)/(1−U_opt)`
- `SupplyAPR ≈ BorrowAPR × U × (1−ReserveFactor)`，另加可分配 staking 收益；不保證固定回報。

風險參數按資產隔離：LTV、Liquidation Threshold、Liquidation Bonus、Supply Cap、Borrow Cap、Debt Ceiling、Oracle Confidence、Isolation Mode。初始示例而非最終參數：ADA LTV 55%、LT 65%；穩定幣 LTV 70%、LT 78%；長尾 CNT 預設不可抵押，待流動性與 oracle 審查後啟用。

`Health Factor = Σ(CollateralValue_i × LT_i) / Σ(DebtValue_j)`；當 HF < 1 可清算。前端建議安全緩衝不得被表述為保證。

### 3.3 ADA PoS 質押不中斷機制

鎖在 script address 的 ADA 使用指定 staking credential；Stake Controller 將其委託至經治理核准的 stake pool 集合。每 epoch 記錄可歸屬獎勵，按 ADA supply shares 與持有期間分配：

1. 使用者存入 ADA，池 datum 更新 principal 與 reward index。
2. 獎勵進入 reward account；提領交易須由 staking validator／多簽政策核准。
3. Keeper 將獎勵再存入 ADA shard、發放給供應者，或依使用者 Opt-in Hook 償還債務。
4. 預留流動性 buffer，避免全部 ADA 因策略或 UTxO 佈局而難以及時提領。

關鍵限制：staking reward 有 epoch 延遲，APY 並非固定；委託集中、池飽和、池停機、會計捨入與獎勵提領權限均需審計。用戶資產所有權與 staking 控制權必須在介面中清楚揭露。

### 3.3A CardFi 自建 Cardano 原生 Stake Pool

CardFi 將以 Stake Pool Operator 身分建立並營運 `[CFI]` 原生質押池，而非聚合或代銷外部池。基礎設施採一個不對公網開放的 Block Producer、至少兩個位於不同供應商／地區的 Relay、獨立監控節點與離線冷鑰環境。冷鑰與 counter 永不進入線上伺服器；Block Producer 僅持有產塊必要的 KES、VRF 與 operational certificate，並建立 KES 週期輪替與告警。

CardFi Wallet 與 Web dApp 提供 `[CFI]` Pool 專頁，顯示 pool ID、pledge、margin、固定成本、飽和度、近期表現、產塊紀錄、Relay 狀態與退休狀態。使用者透過 CIP-30 相容錢包簽署 stake address registration 與 delegation certificate；ADA 仍位於原錢包並可支出。CardFi 作為 SPO 收取鏈上設定的固定成本與 margin，但不保管委託本金，也不手動分配一般委託者獎勵。

### 3.4 eUTXO 閃電貸與 Flash Execution

Flash Loan 在 Cardano 上實作為**單一交易內的暫時流動性使用權**：

1. 交易消耗一個或多個 Liquidity Shard UTxO。
2. 中間輸出／交換／清算均於完整交易圖中聲明。
3. Flash Executor 驗證同資產最終池輸出 `V_out ≥ V_in + fee`，shard NFT、datum schema、reserve 與非 ADA 最小值均正確。
4. 若任一 DEX leg、oracle 條件、slippage 或還款條件失敗，整筆交易不會上鏈。

建議費率：起始 5–9 bps，由治理調整；對經審核的清算 adapter 可有獨立費率。不可把 EVM 的任意 callback 原樣複製；CardFi 採 allowlisted action schema、script hash binding、最大 steps、資產 delta invariant 與禁止未聲明 mint policy。

### 3.5 Smart Vault Hooks

Hook 是受版本控制的交易意圖模組，輸入 Position UTxO、Oracle reference input、策略參數與最小輸出，產生可驗證交易：

- **Leveraged Farming：** 借入穩定幣 → DEX 交換／LP → 將 LP 或策略 receipt 作為受控抵押；設最大 leverage、最小 liquidity 與價格影響上限。
- **Self-Repaying Loans：** 將 staking reward 或策略收益依固定比例換成 debt asset 並 repay；本金仍暴露於抵押品與 oracle 風險。
- **Liquidation Shield：** 當 HF 低於觸發值，從預存 buffer、授權流動性或 flash route 償還部分債務；屬條件式執行，不保證在壅塞、價格跳空或流動性不足時成功。

Hook Registry 儲存 script hash、版本、權限與限額；治理僅上架經 audit 的核心 hooks，第三方 hooks 進入隔離 vault，禁止直接觸碰其他市場狀態。

### 3.6 Batcher 併發設計

- 每市場配置 N 個 shard，依 hash／流動性／負載選擇輸入。
- 使用者簽署限時 intent，而非交付資產保管權；batcher 建構交易但不能改變 owner、max fee、min received、deadline。
- 多 batcher 競爭同一 order UTxO；bond 與可驗證服務指標抑制作惡或審查。
- 失敗 intent 可由其他 batcher 接手；錢包提供 direct-submit fallback。
- 指標：成功率、P50/P95 confirmation、contention retry、每筆執行成本、batcher 集中度。

### 3.7 CardFi 專屬錢包（Mobile／Extension）

- HD key 與 CIP 相容帳戶管理；金鑰留在裝置安全儲存區，協議伺服器只接收已簽名交易。
- 一鍵 Supply／Borrow／Repay／Stake／Flash Strategy；簽名前顯示資產 delta、費用、HF 前後變化與最壞滑點。
- Web dApp 透過標準 Cardano wallet connector 連接 CardFi Wallet 與相容第三方錢包。
- SDK 分層：Query API、Transaction Builder、Simulator、Signer Adapter、Indexer/WebSocket。
- Mobile deep link、hardware wallet、watch-only、phishing domain allowlist、交易人類可讀化與 session permission。

## 4. 安全性、清算與 Flash Execution

### 4.1 安全模型

1. **形式化不變量：** 資產守恆、debt/supply index 單調性、同交易 flash repayment、position ownership、oracle freshness。
2. **測試：** Aiken 單元／屬性／fuzz／state-machine 測試；模擬 oracle 跳價、epoch rollover、shard contention、partial liquidation。
3. **審計：** 至少兩輪獨立審計；公開報告、修復 commit 與再測證明；主網前公開 bug bounty。
4. **防禦：** supply/borrow/debt caps、asset isolation、rate limit、oracle circuit breaker、pause 僅阻止新增風險而保留 repay/withdraw（依償付能力）。
5. **治理安全：** 參數 timelock、Emergency Council 多簽、權限可撤銷、鏈上事件與透明 dashboard。

### 4.2 清算流程

- Keeper 讀取最新合格 oracle reference input，計算 HF。
- HF < 1 時可提交部分清算；close factor 隨危險程度增加，避免小幅波動即全額清算。
- 清算人償還 debt asset，獲得抵押品與 bonus；protocol fee 部分進入 Safety Reserve。
- 價格來源需設定最大年齡、來源數、偏差閾值與 fallback；價格過期時禁止新增借款與清算，允許還款。
- 壞帳依序由該市場 reserve、Safety Module／insurance、治理批准的 recapitalization 處理，避免跨市場無上限傳染。

### 4.3 Flash Execution 特有風險

- DEX 價格操縱：借款與清算不得直接使用同交易 spot price；使用獨立、延遲受控的 oracle。
- Hook 權限擴張：script hash 綁定、資產 allowlist、max borrow、max slippage、禁止任意 datum 解碼。
- Batcher 排序：commit-reveal／批次公平排序、intent deadline、公開 inclusion metrics。
- 大型交易耗盡 shard：per-tx flash cap、動態費率與保留流動性。

## 5. 代幣經濟學與治理

### 5.1 $CFI 功能（設計草案）

- 治理投票與委託；不賦予固定收益或贖回承諾。
- Safety Module 質押，用於明確上限內的壞帳承擔；參與者取得協議激勵並承擔 slashing 風險。
- 費用折扣、開發者 grant 與流動性激勵；激勵應有期限、上限與成效門檻。

### 5.2 建議供應與分配

固定最大供應 **1,000,000,000 CFI**：社群與流動性激勵 35%；生態與開發者 20%；國庫 20%；團隊 15%；策略夥伴／早期支持者 7%；Safety Bootstrap 3%。團隊 12 個月 cliff + 36 個月線性解鎖；策略夥伴 6 個月 cliff + 24 個月解鎖；國庫支出須治理批准。

### 5.3 治理路徑

Phase 1 多簽 + 公開 timelock；Phase 2 Token House 與 Risk Council 雙軌；Phase 3 鏈上 proposal、quorum、delegation；Phase 4 對 treasury、listing、fees、hooks 與 emergency powers 完成最小權限治理。關鍵參數設硬上限與冷卻期，緊急暫停需事後 ratification。

## 6. 開發路線圖（Phase 1–4）

| 階段 | 時程 | 交付 |
|---|---:|---|
| Phase 1 — Core | 月 1–2 | Aiken market/shard/position/oracle/flash validators；動態利率；模擬器；開源測試 |
| Phase 2 — Composability | 月 3 | Smart Vault Hooks API；permissionless batcher MVP；Wallet SDK；Leveraged/Self-Repay 原型 |
| Phase 3 — Testnet & Audit | 月 4–5 | Web dApp、Extension beta、索引器；測試網；兩輪 audit；bug bounty；壓力測試 |
| Phase 4 — Mainnet | 月 6 起 | 限額主網、ADA/穩定幣市場；flash/liquidation SDK；Mobile beta；治理與逐步提高 caps |

主網採 guarded launch：先低 caps、有限資產、監控 2–4 週，再依 audit 與鏈上數據逐步放寬。

---

# 模組二｜CardFi 10 頁 Pitch Deck 簡報內容

## Slide 1｜CardFi：讓 ADA 同時工作兩次
**核心視覺／架構圖建議：** 中央 CardFi 核心，左側 ADA staking、右側 Lending／Flash Execution；底部 Web + Wallet。  
**重點文案：**
- Cardano 原生借貸 × PoS 收益 × EVM 級 DeFi 工具箱
- 一筆原子交易，完成借貸、交換、清算與策略重組
- Hook：`Your ADA keeps staking. Your liquidity keeps moving.`

## Slide 2｜問題：資產在同一條鏈上，體驗卻被切成孤島
**視覺：** 使用者在 Wallet、DEX、Staking、Lending 間多次簽名的斷裂漏斗。  
**重點文案：**
- 流動性分散，資本與操作成本疊加
- 抵押 ADA 的 staking 機會成本降低供給意願
- 缺少標準化 flash liquidity、hook 與清算開發工具
- 單一池 UTxO 設計易 contention；一般用戶難理解交易風險

## Slide 3｜解法：一個協議，四個可組合模組
**視覺：** 四象限：Lending、Yield-bearing ADA、Flash + Hooks、Native Wallet。  
**重點文案：**
- 支援 ADA、DJED、iUSD 與治理核准 CNTs
- 抵押借貸期間按協議規則分配原生 staking rewards
- 原子 Flash Execution + Smart Vault Hooks
- Web dApp 與 Mobile／Extension 一致的交易模擬與風險顯示

## Slide 4｜進階智能合約：把複合策略壓縮成一筆交易
**視覺：** `Borrow → Swap → Action → Repay` 原子環，旁接三個 use case。  
**重點文案：**
- Atomic Flash Loans：無需預先抵押，但同交易必須還本付費
- Leveraged Farming：受限槓桿與滑點邊界
- Self-Repaying Loans：staking／策略收益自動還債
- Liquidation Shield：條件式去槓桿；不承諾必然執行

## Slide 5｜Product Matrix：Web 深度，Wallet 速度
**視覺：** 左 Web 儀表板、右手機錢包，中央共享 SDK。  
**重點文案：**
- Web：市場、倉位、治理、開發者 console、策略模擬
- Wallet：一鍵 supply/borrow/repay、HF 警示、deep link
- 共用 Transaction Builder／Simulator／Indexer；內建 CardFi `[CFI]` Pool 委託
- 簽名前呈現資產 delta、max fee、slippage、HF 變化

## Slide 6｜技術優勢：為 eUTXO 原生設計，不是 EVM 仿製品
**視覺：** 三層架構：Aiken Validators → Sharded eUTXO → Batcher/Solver。  
**重點文案：**
- Aiken 強型別驗證器，編譯至 UPLC
- 完整交易圖與原子性支援可驗證 flash settlement
- Sharded pool + order UTxO 降低 contention
- 多 batcher、bond、fallback 與公開 SLA 降低單點依賴
- 預先估算執行成本；MEV 採減緩而非「歸零」敘事

## Slide 7｜市場機會與財務模型
**視覺：** 收益飛輪：TVL → Borrow demand → Fees → Safety/Dev → 更多整合。  
**重點文案：**
- 收入：reserve factor、flash fee、liquidation protocol share、vault service fee
- North Star：活躍借款餘額 × 可持續淨利差，而非只追 TVL
- 三情境模型：Bear/Base/Bull 以 TVL、利用率與費率推導；禁止把預測寫成保證
- 先 ADA／stablecoin 核心市場，再擴展高流動性 CNT

## Slide 8｜Roadmap：6 個月 guarded mainnet
**視覺：** 四段時間軸與安全閘門。  
**重點文案：**
- M1：核心借貸、oracle、flash validators
- M2：Hooks API、Wallet SDK、batcher MVP
- M3：Web dApp、testnet、audit、bug bounty
- M4：低 caps 主網、機器人／DEX 對接、Mobile beta

## Slide 9｜Team & Advisors
**視覺：** 角色卡與已交付證據連結。  
**重點文案：**
- `[CEO/Protocol Lead｜姓名｜Cardano/DeFi 經歷｜GitHub]`
- `[Aiken Engineer｜姓名｜已部署合約]`
- `[Wallet/Frontend Lead｜姓名｜Mobile/Extension 經歷]`
- `[Security/Risk Advisor｜姓名｜審計/風控履歷]`
- `[Growth/Partnerships｜姓名｜Cardano/EVM 生態資源]`

## Slide 10｜Ask：300,000 ADA，交付可驗證的主網協議
**視覺：** 資金分配 donut + 6 個月里程碑 + QR code。  
**重點文案：**
- Catalyst Ask：300,000 ADA
- 交付：開源 Aiken 合約、Hooks SDK、Wallet SDK、Web dApp、audit、限額主網
- 尋找：audit partner、oracle/DEX、stake pool、market maker、EVM bot builders
- `[Website] [X] [Discord] [GitHub] [Email]`

---

# 模組三｜CardFi Project Catalyst 國庫提案

> 提交前需按當期 Fund challenge、字數、貨幣換算與 milestone 規則微調。下列採 Catalyst 常見的 Impact／Feasibility／Value for Money 與「Outputs、Acceptance Criteria、Evidence」結構。

## 1. 專案標題與 Elevator Pitch

**標題：** CardFi — Cardano 原生質押收益、eUTXO 閃電貸與可程式化金庫的去中心化借貸協議

**Elevator Pitch（約 200 字）：**  
CardFi 將在 Cardano 建立一套開源、非託管的借貸與流動性協議，支援 ADA、DJED、iUSD 與經風險審查的 CNTs。協議以 Aiken 與分片 eUTXO 架構實作超額抵押借貸、動態利率、ADA 質押收益會計、單筆交易原子閃電貸及 Smart Vault Hooks。開發者可透過 EVM 概念相容 SDK 建構套利、清算、槓桿農場與自動償債策略；一般使用者則可在 CardFi Web dApp 與專屬錢包中一鍵完成操作。六個月內交付開源合約、SDK、測試網、獨立審計與限額主網，為 Cardano 引入更成熟的 DeFi 可組合性與開發者工具。

## 2. 問題與解決方案

### 問題
Cardano 擁有原生 PoS 與多資產帳本，但借貸、staking、DEX 與錢包體驗仍相對割裂。開發者缺乏標準化 flash liquidity 與 hook API；用戶操作複合策略需多次簽名，且抵押 ADA 可能產生 staking 機會成本。eUTXO 若採單一共享 UTxO，又會形成 contention。

### 解決方案
CardFi 建立分片流動性池、position UTxO、oracle adapter、Stake Controller、Flash Executor 與 permissionless batcher。單筆交易以資產守恆驗證閃電貸還款；Smart Vault Hooks 將策略限制在明確資產、步驟、滑點與風險上限內。Wallet SDK 與 Web dApp 提供模擬、簽名、監控與人類可讀風險提示。所有核心合約與 SDK 採開源授權，建立可供其他 Cardano dApp 重用的 composability primitive。

## 3. 生態影響力（Impact on Cardano）

- **吸引 EVM 開發者：** 提供 supply/borrow/repay/flashExecute/liquidate/hook 的概念映射、TypeScript SDK、範例 bot 與 migration guide，降低從 Solidity 心智模型切換到 datum/redeemer 與 transaction builder 的成本。
- **吸引套利與清算基礎設施：** 發布 reference bot、模擬器、公共 test vectors、DEX adapter 與 flash fee 規格，使機器人能在 Cardano 上建構原子套利與 permissionless liquidation。
- **提高 ADA 資本效率：** 讓符合協議會計規則的 ADA 抵押仍參與 staking reward 分配，增加供給端誘因。
- **產生公共財：** 開源 Aiken contracts、Hook Registry schema、Wallet SDK、indexer API 與監控 dashboard。
- **可量測外溢：** 追蹤第三方 SDK 整合、獨立 bot、flash volume、borrow volume、活躍地址、batcher 集中度與重用 CardFi 元件的專案數。

本提案不把機器人活動本身等同生態價值；成功標準是增加有效流動性、縮小價格偏差、提高清算可靠度與創造可持續費用，而非單純交易筆數。

## 4. 團隊執行能力與風險控管（Feasibility & Risk Mitigation）

### 團隊（提交前補齊可驗證資料）
- Protocol Lead `[姓名／GitHub／過往主網合約]`
- 2 × Aiken/Off-chain Engineers `[姓名／作品]`
- Wallet & Frontend Lead `[姓名／Mobile/Extension]`
- Security/Risk Lead `[姓名／審計或風控經驗]`
- Product/Growth `[姓名／Cardano 與 EVM 合作紀錄]`

### 執行方法
- 兩週 sprint；公開 backlog、release notes、測試覆蓋率與月度 demo。
- CI 執行 Aiken tests、property/fuzz tests、UPLC cost benchmarks、TypeScript integration tests。
- 里程碑付款僅在 Outputs、Acceptance Criteria 與 Evidence 全部公開後申請。

### 主要風險與緩解
| 風險 | 緩解措施 |
|---|---|
| UTxO contention | 市場分片、多 batcher、intent 重試、direct-submit fallback、壓測 |
| Oracle 操縱／過期 | 多源聚合、staleness/deviation cap、circuit breaker、spot price 禁用 |
| 合約漏洞 | 形式化不變量、fuzz/state-machine、雙輪 audit、bug bounty、低 caps |
| Batcher 審查／中心化 | permissionless bond、可驗證 intent、公開 inclusion metrics、多實作者 |
| Staking 會計或委託集中 | epoch accounting 測試、池分散規則、飽和監控、透明獎勵報表 |
| 市場／穩定幣脫鉤 | isolation mode、borrow/debt caps、LTV haircut、逐資產 pause |
| 進度延誤 | MVP 範圍鎖定；Mobile 完整版與長尾資產不阻擋核心主網 |
| ADA 匯率／預算波動 | 10% contingency；月度 burn report；非必要行銷後置 |

## 5. 六個月里程碑與 Proof of Achievements

### Milestone 1｜核心 Aiken 借貸與閃電貸合約（第 1–2 月；75,000 ADA）
**Outputs：** Registry、Liquidity Shard、Position、Oracle Adapter、Flash Executor；動態利率與 HF 模組；TypeScript transaction builder。  
**Acceptance Criteria：** supply/withdraw/borrow/repay/liquidate/flashExecute 端到端通過；flash 未還本付費必定失敗；至少 90% 關鍵分支測試；成本 benchmark 公開。  
**Evidence：** 公開 GitHub tag、CI URL、測試報告、UPLC benchmark、預錄 testnet demo 與交易連結。

### Milestone 2｜Smart Vault Hooks API 與 Wallet SDK（第 3 月；60,000 ADA）
**Outputs：** Hook Registry、Leveraged Farm／Self-Repay／Liquidation Shield 測試版；Wallet SDK；batcher MVP。  
**Acceptance Criteria：** 三個 hooks 在 preview/preprod 完成成功與故障案例；未上架 script hash、超滑點或超限額交易被拒；兩個獨立 batcher 可處理相同 intent schema。  
**Evidence：** npm/package release、API docs、範例 app、鏈上 tx IDs、contention 壓測與錄影。

### Milestone 3｜Web dApp、合約審計與測試網（第 4–5 月；90,000 ADA）
**Outputs：** Web dApp beta、Extension beta、indexer/dashboard、外部 audit、修復與 bug bounty。  
**Acceptance Criteria：** 核心流程可由公開測試網使用；高／嚴重 audit findings 已修復或有公開處置；完成至少 10,000 筆模擬操作與 500 次並發 intent 壓測；關鍵服務有監控。  
**Evidence：** 公開 beta URL、audit PDF、修復 commit、再測函、壓測資料、bug bounty 頁面、測試網 dashboard。

### Milestone 4｜主網上線、閃電貸對接與推廣（第 6 月；75,000 ADA，含結案與核准後備款）
**Outputs：** guarded mainnet、ADA 與至少一個穩定幣市場、flash/liquidation reference bot、至少兩個 DEX adapter、開發者活動。  
**Acceptance Criteria：** 主網 scripts 與 source hash 可重現；初始 caps 和 pause/repay 路徑驗證；至少 2 個外部整合意向或 1 個實際第三方整合；連續 14 日監控無未處置嚴重事件。  
**Evidence：** 主網 tx/script IDs、reproducible build、運行 dashboard、整合 repo／合作證明、活動錄影、事件報告。

### Final Close-out｜結案報告與影片（納入 M4 預算）
**Outputs：** Catalyst close-out report、close-out video、完整預算與 KPI 對照。  
**Acceptance Criteria：** 公開列出原承諾、實際交付、差異、持續維運計畫與可驗證連結。  
**Evidence：** 公開報告 URL、影片 URL、最終 GitHub release 與財務摘要。

## 6. 預算分配細目（300,000 ADA）

| 項目 | ADA | 占比 | 說明 |
|---|---:|---:|---|
| Aiken 核心合約與 off-chain engineering | 82,000 | 27.3% | 市場、倉位、oracle、flash、利率、測試 |
| Wallet SDK、Web dApp、Extension | 48,000 | 16.0% | SDK、UI、交易模擬、簽名與索引 |
| Smart Vault Hooks、Batcher、Bot SDK | 36,000 | 12.0% | 三個 hooks、solver/batcher、reference bots |
| 外部安全審計與再測 | 55,000 | 18.3% | 至少一家具名第三方；範圍與報告公開 |
| DevOps、Indexer、測試網與監控 | 20,000 | 6.7% | 節點／provider、CI、dashboard、alerts |
| Bug bounty 與測試激勵 | 15,000 | 5.0% | 分級獎勵，未用款退回／轉國庫須治理批准 |
| 開發者文件、活動與合作整合 | 14,000 | 4.7% | migration guide、workshop、DEX/oracle adapters |
| 專案管理、Catalyst 報告與法遵 | 10,000 | 3.3% | sprint、里程碑證據、條款與風險揭露 |
| Contingency | 20,000 | 6.7% | 價格、重審與基礎設施波動；動用需公開說明 |
| **總計** | **300,000** | **100.0%** | — |

**Value for Money：** 資金換取可重用的開源協議 primitive、開發者 SDK、安全審計、公開測試證據與限額主網，而非僅概念設計或封閉產品。每月公開 ADA burn、法幣等值假設、承包商支出與剩餘預算。

## 7. 關鍵績效指標（KPIs）

### 六個月交付 KPI
- 5+ 核心 Aiken validators／policies 開源，100% 可重現 build。
- 關鍵不變量 100% 對應測試；關鍵分支覆蓋 ≥90%；0 個未處置 Critical/High audit finding 上主網。
- 測試網 ≥10,000 筆模擬操作、≥500 次並發 intent 壓測；成功率 ≥95%（排除明確使用者無效輸入）。
- Web dApp + Extension beta + Wallet SDK + Hooks SDK 各 1 套。
- 2 個 DEX adapters；≥3 個外部開發團隊試用 SDK；≥1 個第三方整合上線或進入公開測試。
- guarded mainnet 連續 14 日監控；事件回應 SLA 與公開 status page 上線。

### 上線後 90 日結果 KPI（目標，不作保證）
- 1,000 個獨立活躍地址；300 個活躍借款倉位。
- TVL 5M ADA、平均借款利用率 25–60%。
- 累積 flash volume 2M ADA 等值、成功原子執行 ≥1,000 筆。
- 清算成功率 ≥95%；壞帳率 <0.5% 借款餘額；oracle stale 導致錯誤清算 = 0。
- 前四大 batcher 之外仍有至少 1 個獨立運行者；最大單一 batcher inclusion share <50%。
- 3 個公開第三方 bots／hooks／dApps 使用 CardFi SDK。

---

# 官方資料依據與提交前核對

- Aiken 官方說明其為 Cardano 專用、純函數式、強型別語言並編譯到 UPLC；本文因此將其定位為 validator 工具，而非 EVM runtime。
- Aave 官方資料用於 LTV、Health Factor、動態利率與 permissionless liquidation 的概念基準；CardFi 參數不照搬，需重新做 Cardano 資產風險分析。
- Catalyst 過往／現行指南要求里程碑包含 Outputs、Acceptance Criteria 與 Evidence，且 funded project 另有 close-out 流程；正式提交仍以當期 challenge 設定為準。
