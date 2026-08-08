# CardFi 部署指南 / Deployment Guide

## 1. 本機展示 / Local showcase

需求：Node.js 24、npm。

```powershell
git clone https://github.com/doki03164/CARDFI.git
Set-Location CARDFI
git checkout cardfi-mvp
npm.cmd ci
npm.cmd test
npm.cmd run build
npm.cmd run dev -- --host 127.0.0.1 --port 5173
```

開啟 `http://127.0.0.1:5173/`。右上角 `EN／繁中` 可切換語言。

## 2. GitHub Pages

Repository 已包含 `.github/workflows/pages.yml`。首次部署：

1. 開啟 GitHub Repository。
2. 進入 `Settings → Pages`。
3. 在 `Build and deployment → Source` 選擇 `GitHub Actions`。
4. 進入 `Actions → Deploy CardFi Showcase to GitHub Pages`。
5. 點選 `Run workflow`，Branch 選 `cardfi-mvp`。
6. 等待 `build` 與 `deploy` 完成。
7. 預期網址：`https://doki03164.github.io/CARDFI/`。

Workflow 會執行測試，並以 `/CARDFI/` 作為 Vite base path 建置。部署失敗時先查看 Actions log，確認 Pages Source 已設為 GitHub Actions。

GitHub 官方 Pages workflow 說明：https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages

## 3. Vercel

1. 在 Vercel 選擇 `Add New → Project`。
2. 匯入 `doki03164/CARDFI`。
3. Branch 選 `cardfi-mvp`。
4. Framework Preset 選 `Vite`。
5. Install Command：`npm ci`。
6. Build Command：`npm run build`。
7. Output Directory：`dist`。
8. 加入需要的 `VITE_*` 環境變數後部署。

目前展示版即使未設定 Provider 也能運行 deterministic demo。接入真實 Preprod 前，必須設定可信 Provider、Indexer 與 Oracle 服務，並移除無效範例 URL。

## 4. 一般靜態主機

```powershell
npm.cmd ci
npm.cmd run build
```

將 `dist/` 內容上傳至支援 SPA 的靜態主機。根網域部署使用預設 base；子路徑部署使用：

```powershell
npm.cmd run build -- --base /YOUR_SUBPATH/
```

主機需將未知路由回退至 `index.html`。目前 CardFi 未使用前端 router，因此主要入口不受影響。

## 5. 完整驗證

```powershell
npm.cmd test
npm.cmd run build
npm.cmd run contracts:check
npm.cmd run contracts:build
npm.cmd run deploy:manifest:check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\infra\stake-pool\scripts\verify-templates.ps1"
```

## 6. Cardano Preprod 合約部署狀態

`deploy/preprod.manifest.json` 是由 `contracts/plutus.json` 確定性產生的參數化清單。其狀態目前為 `parameterization-required`，因此它是部署輸入，不是已完成的鏈上部署證明。

```powershell
npm.cmd run contracts:build
npm.cmd run deploy:manifest
npm.cmd run deploy:manifest:check
```

正式 Preprod 部署還需要：

1. 建立 Governance、Oracle、Market Shard 與 Position identity policies。
2. 將 manifest 中的 `<..._CBOR>` 槽替換成 canonical CBOR 參數。
3. 參數化並序列化四個 Validators。
4. 建立 Governance 與 Oracle 初始 state UTxOs。
5. 建立 Market Shard UTxOs 及流動性資產。
6. 記錄 script address、Tx ID、output index、network magic、datum 與 redeemer。
7. 用 explorer、重放命令及 transaction-level tests 驗證。

在鏈下交易建構器完成前，不應把 manifest 的 hash 當成已部署地址。

## 7. `[CFI]` ADA Stake Pool 部署

詳見 `infra/stake-pool/README.md`。高階順序：

1. 準備隔離的 Block Producer 與至少兩個 Relay。
2. 安裝相容版本的 `cardano-node`／`cardano-cli`。
3. 產生 cold、VRF、KES 與 operational certificate；cold key 離線保存。
4. 更新 topology、systemd、metadata 與環境槽位。
5. 先執行 `verify-templates.ps1`。
6. 依網路參數提交 pool registration、pledge 與 delegation certificates。
7. 啟用 metrics、告警、KES 到期與磁碟監控。

目前 `[CFI]` 為 configuration-ready／provision-pending，尚未宣稱主網註冊或出塊。

## 8. Environment variables

以 `.env.example` 建立本機 `.env`：

```dotenv
VITE_CARDANO_NETWORK=preprod
VITE_PROVIDER_URL=https://YOUR_PROVIDER
VITE_PROVIDER_PROJECT_ID=YOUR_PROJECT_ID
VITE_ORACLE_MAX_AGE_SECONDS=120
```

不要把 API key、seed phrase、cold key、KES/VRF secret 或私有 Provider credential 提交到 Git。
