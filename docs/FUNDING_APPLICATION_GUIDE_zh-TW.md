# CardFi 資金申請操作指南

更新日期：2026-08-08

## 一、目前應採取的策略

Project Catalyst 正在進行管理權移交。官方於 2026 年 2 月說明 Fund15 暫停，其後並確認原規劃的 Fund15／Fund16 不會照原形式運行，相關 ADA 返回國庫。因此，目前的正確策略不是提交一份已關閉輪次的表單，而是先完成 Catalyst 帳戶、團隊證明、公開成果、里程碑與預算，等下一輪正式公告後再依新規則調整數字並送件。

官方參考：

- Catalyst 更新：https://projectcatalyst.io/blog/update-from-the-catalyst-team
- Cardano Foundation 2026 年 5 月更新：https://cardanofoundation.org/blog/may-2026-activities
- Catalyst 工具與帳戶設定：https://docs.projectcatalyst.io/catalyst-tools/catalyst-app/getting-started

## 二、CardFi 現在已具備的申請證據

1. 公開 GitHub Repository 與可追溯 Commit。
2. 可操作 Web 展示產品，包括借貸、Flash Loan、Vault Hooks、治理與 `[CFI]` 原生委託流程。
3. 四個可重現編譯的 Plutus V3 Validators：Governance、Market、Oracle、Position。
4. 借貸／還款原子同步、Oracle LTV、Flash fee、清算門檻、Close Factor、清算獎勵與治理金鑰輪替。
5. CIP-57 Blueprint、Preprod 參數清單、GitHub CI 與 27 個 Aiken 測試。
6. CardFi 自建 ADA Stake Pool 的 topology、systemd、metadata、註冊與驗證範本。
7. 輕量白皮書、10 頁 Pitch Deck 大綱及 Catalyst 提案初稿。

## 三、帳戶與送件操作

當下一輪 Catalyst 開放後：

1. 前往 Catalyst App。
2. 建立 Profile 與 Catalyst Keychain。
3. 使用支援 CIP-30 的 Cardano 瀏覽器錢包連線；官方文件目前建議準備至少 5 ADA，用於建立鏈上身分關聯與支付交易費。
4. 在 Keychain 加入 `Proposer` 角色。
5. 進入 `Workspace → My Proposals → Create Proposal`。
6. 選擇最接近「Cardano Use Cases／Prototype & Launch」的技術產品類別；必須以新一輪正式 Category Brief 為準。
7. 完成全部欄位後先發布為公開 Draft，收集社群意見。
8. 修正文案、預算、里程碑與團隊證據。
9. 截止前發布為 Final；公開 Draft 本身不具投票與獲款資格。

操作參考：https://docs.projectcatalyst.io/catalyst-tools/catalyst-app/create-and-submit-proposals-in-workspace

## 四、建議的申請定位

**提案名稱**

CardFi — Yield-Bearing Lending, Atomic Flash Execution and Native ADA Staking Infrastructure

**申請成果，不申請既有成果的費用**

既有程式、白皮書與展示產品列為團隊先期投入及能力證明。申請款只用於未來工作：Preprod 整合、鏈下服務、Vault Hooks、安全審計、Stake Pool 部署、主網準備及社群驗證。

**建議申請規模**

以 Fund15 已公布但後來取消的 `Prototype & Launch` 上限作參考，可先準備 **180,000 ADA／6 個月**版本。下一輪的最低、最高金額與類別規則可能不同，開放後再調整。

## 五、180,000 ADA 預算草案

| 工作包 | ADA | 交付成果 |
|---|---:|---|
| 鏈下交易建構器、Indexer、Batcher | 42,000 | 可重現 Supply/Borrow/Repay/Flash/Liquidate 交易 |
| Preprod 部署與 Oracle feeder | 28,000 | 公開合約地址、參數、交易與監控證據 |
| Smart Vault Hooks 與 Wallet SDK | 30,000 | Hook API、白名單、滑點及到期限制 |
| 第三方安全審計與修復 | 45,000 | Audit report、修復 Commit、重測報告 |
| `[CFI]` Stake Pool 節點及監控 | 15,000 | Relay／BP 部署、註冊與監控證據 |
| 文件、社群測試、專案管理及報告 | 20,000 | 文件、測試活動、月報、Close-out |
| **合計** | **180,000** | 6 個月公開測試網產品 |

## 六、建議里程碑與 Proof of Achievement

### Milestone 1 — Transaction Builder（第 1–2 月，42,000 ADA）

- 產出：五種核心交易建構器、Indexer schema、Batcher shard selector。
- 驗收：公開測試、固定測試向量、CI、可重現命令及成功／失敗交易紀錄。

### Milestone 2 — Preprod Protocol（第 2–3 月，43,000 ADA）

- 產出：參數化四個 Validators、Governance／Oracle／Market 初始 UTxO、Oracle feeder。
- 驗收：Cardano explorer 連結、script hash、Tx ID、部署 manifest 與監控畫面。

### Milestone 3 — Wallet and Vault Hooks（第 3–4 月，30,000 ADA）

- 產出：CIP-30 簽署提交、Flash Lab、三種 Hook 範例。
- 驗收：Web dApp 公開網址、SDK 文件、端對端錄影及鏈上交易。

### Milestone 4 — Audit and SPO（第 4–5 月，45,000 ADA）

- 產出：第三方審計、修復版本、`[CFI]` Relay／BP 基礎設施。
- 驗收：公開審計摘要、修復對照、池註冊或測試環境運行證據。

### Milestone 5 — Public Beta and Close-out（第 6 月，20,000 ADA）

- 產出：公開 Beta、社群測試、KPI dashboard、最終報告與影片。
- 驗收：使用者與交易數據、Issue 關閉紀錄、Close-out report/video。

## 七、Reviewer 最重視的三個回答

### Impact

- CardFi 會產生哪些 Cardano 鏈上交易：Supply、Withdraw、Borrow、Repay、Liquidate、Flash、Governance、Oracle Update、Stake Delegation。
- 如何量測：獨立地址、Redeemer 類型、月活錢包、交易成功率、TVL、借款量、Flash volume、委託者數。
- 為何必須使用 Cardano：eUTXO 原子性、原生資產、低成本確定性驗證、原生 PoS 委託。

### Feasibility

- 不只放概念圖；直接提供 GitHub、CI、Validator hashes、測試結果、Web demo 和部署 manifest。
- 每位團隊成員提供姓名、角色、LinkedIn／GitHub、過往成果及每月可投入時間。
- 外包審計、設計或節點服務應提供合作證明或報價依據。

### Value for Money

- 每一筆 ADA 必須對應工作包、負責人、期間與公開交付物。
- 審計、基礎設施、管理、文件與社群工作不可藏在模糊的「開發費」。
- 說明 CardFi 團隊已自行投入的程式與設計，但不把已完成工作列為追溯報銷。

## 八、正式送件前缺少的資料

1. 法人或主提案人法定資料。
2. 團隊真實姓名、GitHub、LinkedIn、Cardano／EVM 經驗。
3. 每位成員的工作量、月費率與利益關係揭露。
4. 審計公司候選名單、報價或合作意向。
5. 可公開的產品網址；目前 localhost 僅適合現場展示。
6. 社群入口：X、Discord／Telegram、Email 與品牌網域。
7. 下一輪正式 Category Brief、金額限制、截止日期及自我評估表。

## 九、備用資金路徑

- **下一輪 Project Catalyst：**最適合 6–12 個月 Cardano 公開產品交付，但需等待新的正式公告。
- **下一年度 Intersect 預算流程：**適合較大、策略性與可量測的國庫請求；2026 流程已進入投票／結果階段，應為下一週期提前準備。
- **Innovation & Growth DAO：**2026 預算流程中曾提出 20,000–300,000 ADA 的小型專案輪次，但它本身仍屬治理提案／機制，只有在正式通過並公告收件後才提交。
- **Cardano Accelerator／Venture Hub：**偏向已有交易、法人、至少三名全職成員及財務預測的公司；CardFi 完成 Preprod 和組隊後較合適。

不要為了趕申請而宣稱尚未發生的 TVL、主網部署、審計、Stake Pool 出塊或合作關係。展示資料與鏈上實績應始終分開標示。
