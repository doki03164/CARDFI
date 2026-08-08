import { useMemo, useState } from 'react';
import {
  Activity, ArrowDownLeft, ArrowUpRight, BarChart3, Bell, ChevronDown,
  CircleDollarSign, Code2, CreditCard, Droplets, ExternalLink, Gauge,
  Layers3, Menu, Orbit, Search, Server, ShieldCheck, Sparkles, Wallet, X, Zap,
} from 'lucide-react';
import { compactUsd, flashFee, healthFactor, markets, maxBorrow, utilization, type Market } from './lib/protocol';
import { connectCardanoWallet, shortAddress, type WalletSession } from './lib/cardano';

type Action = 'Supply' | 'Borrow' | 'Flash';

interface DemoReceipt {
  title: string;
  detail: string;
  txId: string;
}

interface StakePool {
  ticker: string;
  name: string;
  roa: number;
  saturation: number;
  margin: number;
  pledge: string;
  status: 'Producing' | 'Stable' | 'Planned';
}

const cardFiPool: StakePool = {
  ticker: 'CFI', name: 'CardFi Native Stake Pool', roa: 3.42,
  saturation: 0, margin: 2.0, pledge: '₳500K', status: 'Planned',
};

const formatNumber = (value: number, digits = 2) =>
  new Intl.NumberFormat('en-US', { maximumFractionDigits: digits }).format(value);

function AssetIcon({ market, small = false }: { market: Market; small?: boolean }) {
  return <span className={`asset-icon ${small ? 'small' : ''}`} style={{ '--asset': market.color } as React.CSSProperties}>{market.symbol.slice(0, 1)}</span>;
}

function Sparkline({ color }: { color: string }) {
  return (
    <svg className="sparkline" viewBox="0 0 92 28" aria-hidden="true">
      <path d="M2 23 C12 19, 15 22, 23 14 S38 20, 46 11 S58 17, 67 8 S80 12, 90 3" fill="none" stroke={color} strokeWidth="2" />
    </svg>
  );
}

function ActionModal({ action, market, onClose, onSubmit }: { action: Action; market: Market; onClose: () => void; onSubmit: (receipt: DemoReceipt) => void }) {
  const [amount, setAmount] = useState('1000');
  const numeric = Math.max(0, Number(amount) || 0);
  const usd = numeric * market.price;
  const isFlash = action === 'Flash';
  const buttonLabel = action === 'Supply' ? '確認供應資產' : action === 'Borrow' ? '確認借入資產' : '建立原子交易';
  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={onClose}>
      <section className="modal" role="dialog" aria-modal="true" aria-label={`${action} ${market.symbol}`} onMouseDown={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <div><span className="eyebrow">{action === 'Flash' ? 'FLASH EXECUTION' : 'MARKET ACTION'}</span><h2>{action} {market.symbol}</h2></div>
          <button className="icon-button" onClick={onClose} aria-label="關閉"><X size={18} /></button>
        </div>
        <div className="amount-box">
          <label htmlFor="amount">輸入數量</label>
          <div className="amount-row">
            <input id="amount" inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus />
            <button className="asset-select"><AssetIcon market={market} small /> {market.symbol}<ChevronDown size={14} /></button>
          </div>
          <span>≈ {compactUsd(usd)}</span>
        </div>
        <div className="modal-metrics">
          {action === 'Supply' && <><span>供應 APY</span><strong className="positive">{market.supplyApr}%</strong><span>最大 LTV</span><strong>{market.ltv}%</strong></>}
          {action === 'Borrow' && <><span>借款 APY</span><strong>{market.borrowApr}%</strong><span>所需抵押品</span><strong>{compactUsd(usd / (market.ltv / 100))}</strong></>}
          {isFlash && <><span>協議費（7 bps）</span><strong>{formatNumber(flashFee(numeric))} {market.symbol}</strong><span>原子償還</span><strong>{formatNumber(numeric + flashFee(numeric))} {market.symbol}</strong></>}
        </div>
        <div className="safety-note"><ShieldCheck size={18} /><span>交易提交前會模擬所有資產變化；若最終條件不成立，整筆交易失敗。</span></div>
        <button className="primary wide" onClick={() => onSubmit({
          title: `${action} ${market.symbol} 模擬成功`,
          detail: `${formatNumber(numeric)} ${market.symbol} · ${action === 'Flash' ? `原子償還 ${formatNumber(numeric + flashFee(numeric))}` : compactUsd(usd)}`,
          txId: `sim_${action.toLowerCase()}_${market.symbol.toLowerCase()}_${Math.round(numeric * 1000).toString(16)}`,
        })}>{buttonLabel}<ArrowUpRight size={17} /></button>
        <p className="demo-note">Demo 模式｜尚未連接 Cardano 測試網</p>
      </section>
    </div>
  );
}

function StakeModal({ pool, onClose, onSubmit }: { pool: StakePool; onClose: () => void; onSubmit: (receipt: DemoReceipt) => void }) {
  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={onClose}>
      <section className="modal" role="dialog" aria-modal="true" aria-label={`委託至 ${pool.ticker}`} onMouseDown={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <div><span className="eyebrow">CARDANO NATIVE STAKING</span><h2>委託至 [{pool.ticker}]</h2></div>
          <button className="icon-button" onClick={onClose} aria-label="關閉"><X size={18} /></button>
        </div>
        <div className="stake-summary">
          <div><span>Stake Pool</span><strong>{pool.name}</strong></div>
          <div><span>近 30 日 ROA</span><strong className="positive">{pool.roa}%</strong></div>
          <div><span>飽和度</span><strong>{pool.saturation}%</strong></div>
          <div><span>Pool Margin</span><strong>{pool.margin}%</strong></div>
        </div>
        <div className="native-stake-note"><Server size={19} /><div><b>原生鏈上委託，不是借貸存款</b><span>ADA 保留在你的錢包；交易只提交 stake address registration／delegation certificate。沒有鎖倉，仍可隨時支出。</span></div></div>
        <div className="safety-note"><ShieldCheck size={18} /><span>實際獎勵取決於池表現、飽和度、固定成本、margin 與 Cardano 網路參數，不保證固定 APY。</span></div>
        <button className="primary wide" onClick={() => onSubmit({
          title: `委託 [${pool.ticker}] 模擬成功`,
          detail: 'Stake registration + delegation certificates · ADA 不離開錢包',
          txId: 'sim_delegate_cfi_001',
        })}>建立鏈上委託交易<ArrowUpRight size={17} /></button>
        <p className="demo-note">Demo 模式｜正式版將透過 CIP-30 錢包簽署委託憑證</p>
      </section>
    </div>
  );
}

function WorkspacePanel({
  active,
  wallet,
  onConnect,
  onAction,
  onStake,
}: {
  active: string;
  wallet: WalletSession | null;
  onConnect: () => void;
  onAction: (action: Action, market: Market) => void;
  onStake: () => void;
}) {
  if (active === '總覽') return null;

  if (active === '市場') return <section className="workspace-panel">
    <div className="workspace-head"><div><span className="eyebrow">LIVE DEMO MARKETS</span><h2>借貸市場操作台</h2><p>選擇供應或借款，預覽利率、LTV 與模擬交易結果。</p></div><Droplets size={24} /></div>
    <div className="workspace-grid four">{markets.map((market) => <article className="workspace-card" key={market.symbol}>
      <div className="workspace-asset"><AssetIcon market={market} /><div><b>{market.symbol}</b><small>{market.name}</small></div></div>
      <dl><div><dt>供應 APY</dt><dd className="positive">{market.supplyApr}%</dd></div><div><dt>借款 APY</dt><dd>{market.borrowApr}%</dd></div><div><dt>最大 LTV</dt><dd>{market.ltv}%</dd></div></dl>
      <div className="workspace-actions"><button onClick={() => onAction('Supply', market)}>供應</button><button onClick={() => onAction('Borrow', market)}>借款</button></div>
    </article>)}</div>
  </section>;

  if (active === '我的倉位') return <section className="workspace-panel">
    <div className="workspace-head"><div><span className="eyebrow">POSITION CONTROL</span><h2>倉位與風險中心</h2><p>抵押、債務、原生 PoS 收益及清算邊界集中展示。</p></div><Gauge size={24} /></div>
    <div className="workspace-grid three">
      <article className="workspace-card metric"><span>健康係數</span><strong>{wallet ? '2.06' : '—'}</strong><small>{wallet ? '安全區間 · 清算門檻 80%' : '連接錢包後顯示'}</small></article>
      <article className="workspace-card metric"><span>ADA 抵押收益</span><strong className="positive">3.41%</strong><small>借貸抵押與 CardFi SPO 委託分開計算</small></article>
      <article className="workspace-card metric"><span>可借額度</span><strong>{wallet ? '$4.33K' : '—'}</strong><small>Governance LTV 上限 70%</small></article>
    </div>
    {!wallet && <button className="primary workspace-connect" onClick={onConnect}>連接 Demo／CIP-30 錢包</button>}
  </section>;

  if (active === 'Flash Lab') return <section className="workspace-panel flash-workspace">
    <div className="workspace-head"><div><span className="eyebrow">ATOMIC EXECUTION LAB</span><h2>Flash Loan 情境模擬器</h2><p>借出、策略呼叫、償還與費用必須在同一筆 Cardano 交易中成立。</p></div><Zap size={24} /></div>
    <div className="flow-line"><span>01 借出流動性</span><i /><span>02 執行 Hook</span><i /><span>03 原子償還</span><i /><span>04 Validator 驗證</span></div>
    <div className="workspace-grid three"><article className="workspace-card"><b>套利路由</b><p>DEX_A → DEX_B 價差模擬</p><button onClick={() => onAction('Flash', markets[0])}>模擬 ADA Flash</button></article><article className="workspace-card"><b>閃電清算</b><p>還債並領取受限清算獎勵</p><button onClick={() => onAction('Flash', markets[1])}>模擬 DJED 清算</button></article><article className="workspace-card"><b>費用模型</b><p>7 bps · 100,000 ADA 範例</p><strong className="positive">70 ADA</strong></article></div>
  </section>;

  if (active === 'ADA 鏈上質押') return <section className="workspace-panel">
    <div className="workspace-head"><div><span className="eyebrow">CARDIFI STAKE POOL</span><h2>[CFI] 原生 ADA 委託</h2><p>CardFi 自建 Stake Pool；ADA 留在用戶錢包，僅簽署鏈上委託憑證。</p></div><Server size={24} /></div>
    <div className="workspace-grid three"><article className="workspace-card metric"><span>部署狀態</span><strong>Config Ready</strong><small>Block Producer／Relay 範本已驗證</small></article><article className="workspace-card metric"><span>Pool Margin</span><strong>2.0%</strong><small>展示參數，註冊前可調整</small></article><article className="workspace-card metric"><span>資產託管</span><strong className="positive">Non-custodial</strong><small>無鎖倉、不移轉 ADA 本金</small></article></div>
    <button className="primary workspace-connect" onClick={onStake}>建立 [CFI] 委託模擬</button>
  </section>;

  if (active === 'Vault Hooks') return <section className="workspace-panel">
    <div className="workspace-head"><div><span className="eyebrow">PROGRAMMABLE VAULTS</span><h2>Smart Vault Hooks</h2><p>展示第三方策略如何在資產白名單、滑點與到期時間限制內組合 CardFi。</p></div><Code2 size={24} /></div>
    <div className="workspace-grid three"><article className="workspace-card"><b>Leveraged Farming</b><p>供應 → 借款 → DEX 流動性，一鍵原子路由。</p><span className="status-tag">SPEC READY</span></article><article className="workspace-card"><b>Self-Repaying Loan</b><p>將 PoS／策略收益按週期自動抵扣債務。</p><span className="status-tag">SPEC READY</span></article><article className="workspace-card"><b>Liquidation Shield</b><p>健康係數接近門檻時執行受限去槓桿。</p><span className="status-tag">SPEC READY</span></article></div>
  </section>;

  return <section className="workspace-panel">
    <div className="workspace-head"><div><span className="eyebrow">ON-CHAIN GOVERNANCE</span><h2>協議風險控制中心</h2><p>Governance NFT 統一發布市場、清算與 Oracle 授權參數。</p></div><Orbit size={24} /></div>
    <div className="governance-strip"><span>Max LTV <b>70%</b></span><span>Liquidation <b>80%</b></span><span>Close Factor <b>50%</b></span><span>Bonus <b>5%</b></span></div>
    <div className="validator-list"><div><ShieldCheck size={17} /><span>Governance Validator</span><code>64b0d65a…0de31</code><em>COMPILED</em></div><div><ShieldCheck size={17} /><span>Market Validator</span><code>14c01b49…13200</code><em>COMPILED</em></div><div><ShieldCheck size={17} /><span>Oracle Validator</span><code>6651fbd6…2a73f</code><em>COMPILED</em></div><div><ShieldCheck size={17} /><span>Position Validator</span><code>1aa08896…57f32</code><em>COMPILED</em></div></div>
  </section>;
}

function App() {
  const [active, setActive] = useState('總覽');
  const [wallet, setWallet] = useState<WalletSession | null>(null);
  const [walletError, setWalletError] = useState('');
  const [mobileNav, setMobileNav] = useState(false);
  const [modal, setModal] = useState<{ action: Action; market: Market } | null>(null);
  const [stakeModal, setStakeModal] = useState<StakePool | null>(null);
  const [query, setQuery] = useState('');
  const [receipt, setReceipt] = useState<DemoReceipt | null>(null);

  const totalSupplied = markets.reduce((sum, m) => sum + m.supplied * m.price, 0);
  const totalBorrowed = markets.reduce((sum, m) => sum + m.borrowed * m.price, 0);
  const protocolUtilization = utilization(totalSupplied, totalBorrowed);
  const userCollateral = wallet ? 18_450 : 0;
  const userDebt = wallet ? 5_820 : 0;
  const hf = healthFactor(userCollateral, userDebt);
  const filtered = useMemo(() => markets.filter((m) => `${m.symbol} ${m.name}`.toLowerCase().includes(query.toLowerCase())), [query]);

  const handleConnect = async () => {
    if (wallet) { setWallet(null); return; }
    try {
      setWalletError('');
      setWallet(await connectCardanoWallet());
    } catch (error) {
      setWalletError(error instanceof Error ? error.message : '錢包連線失敗');
    }
  };

  const handleDemoSubmit = (nextReceipt: DemoReceipt) => {
    setReceipt(nextReceipt);
    setModal(null);
    setStakeModal(null);
  };

  const nav = [
    { label: '總覽', icon: BarChart3 }, { label: '市場', icon: Droplets },
    { label: '我的倉位', icon: Wallet }, { label: 'Flash Lab', icon: Zap },
    { label: 'ADA 鏈上質押', icon: Server }, { label: 'Vault Hooks', icon: Code2 }, { label: '治理', icon: Orbit },
  ];

  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileNav ? 'open' : ''}`}>
        <div className="brand"><span className="brand-mark"><Layers3 size={22} /></span><span>Card<span>Fi</span></span></div>
        <nav>
          <p className="nav-label">PROTOCOL</p>
          {nav.map(({ label, icon: Icon }) => <button key={label} className={active === label ? 'active' : ''} onClick={() => { setActive(label); setMobileNav(false); }}><Icon size={18} /><span>{label}</span>{label === 'Flash Lab' && <em>NEW</em>}</button>)}
        </nav>
        <div className="sidebar-bottom">
          <div className="network"><i /> Cardano {wallet?.networkName ?? 'Preprod'} <ChevronDown size={14} /></div>
          <a href="#docs"><Code2 size={16} />開發者文件<ExternalLink size={13} /></a>
          <a href="#security"><ShieldCheck size={16} />安全中心<ExternalLink size={13} /></a>
        </div>
      </aside>

      <main>
        <header>
          <button className="menu-button" onClick={() => setMobileNav(!mobileNav)} aria-label="開啟導覽"><Menu size={20} /></button>
          <div className="status-pill"><i /> Demo environment operational</div>
          <div className="header-actions">
            <button className="icon-button"><Bell size={18} /></button>
            <button className={`wallet-button ${wallet ? 'connected' : ''}`} onClick={handleConnect}>
              <Wallet size={17} />{wallet ? shortAddress(wallet.addressHex) : '連接錢包'}
            </button>
          </div>
        </header>

        <div className="content">
          {receipt && <section className="receipt-banner" role="status"><ShieldCheck size={19} /><div><b>{receipt.title}</b><span>{receipt.detail}</span><code>{receipt.txId}</code></div><button className="icon-button" onClick={() => setReceipt(null)} aria-label="關閉結果"><X size={16} /></button></section>}
          <section className="hero-row">
            <div><span className="eyebrow">CARDANO LIQUIDITY LAYER</span><h1>{active === '總覽' ? '早安，Builder' : active}<span className="dot">.</span></h1><p>{active === '總覽' ? '讓抵押品持續產生收益，讓流動性無縫移動。' : 'CardFi 可操作展示環境 · 所有提交均為確定性模擬。'}</p></div>
            <div className="hero-actions">
              <button className="secondary" onClick={() => setModal({ action: 'Supply', market: markets[0] })}><ArrowDownLeft size={17} />供應資產</button>
              <button className="primary" onClick={() => setModal({ action: 'Borrow', market: markets[1] })}><ArrowUpRight size={17} />借入資產</button>
            </div>
          </section>

          <WorkspacePanel active={active} wallet={wallet} onConnect={handleConnect} onAction={(action, market) => setModal({ action, market })} onStake={() => setStakeModal(cardFiPool)} />

          <div className={`overview-content ${active === '總覽' ? '' : 'hidden'}`}>
          <section className="stat-grid">
            <article className="stat-card"><div className="stat-title"><span>總供應量</span><CircleDollarSign size={18} /></div><strong>{compactUsd(totalSupplied)}</strong><div className="stat-foot"><span className="positive">↗ 8.4%</span><small>過去 30 天</small><Sparkline color="#15d39a" /></div></article>
            <article className="stat-card"><div className="stat-title"><span>總借款量</span><CreditCard size={18} /></div><strong>{compactUsd(totalBorrowed)}</strong><div className="stat-foot"><span className="positive">↗ 12.1%</span><small>過去 30 天</small><Sparkline color="#83a7ff" /></div></article>
            <article className="stat-card featured"><div className="stat-title"><span>協議利用率</span><Gauge size={18} /></div><strong>{protocolUtilization.toFixed(1)}%</strong><div className="util-track"><i style={{ width: `${protocolUtilization}%` }} /></div><div className="stat-foot"><small>最佳區間 45–75%</small><span>Healthy</span></div></article>
            <article className="stat-card"><div className="stat-title"><span>Flash Volume</span><Zap size={18} /></div><strong>$4.82M</strong><div className="stat-foot"><span className="positive">↗ 21.6%</span><small>近 7 天</small><Sparkline color="#d6ff62" /></div></article>
          </section>

          <section className="dashboard-grid">
            <article className="panel markets-panel">
              <div className="panel-head"><div><h2>資產市場</h2><p>即時利率與流動性概況</p></div><div className="search"><Search size={16} /><input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="搜尋資產" /></div></div>
              <div className="market-table">
                <div className="table-row table-head"><span>資產</span><span>總供應</span><span>供應 APY</span><span>借款 APY</span><span>利用率</span><span /></div>
                {filtered.map((market) => (
                  <div className="table-row" key={market.symbol}>
                    <span className="asset-cell"><AssetIcon market={market} /><b>{market.symbol}<small>{market.name}</small></b></span>
                    <span>{compactUsd(market.supplied * market.price)}</span>
                    <span className="positive">{market.supplyApr.toFixed(2)}%</span>
                    <span>{market.borrowApr.toFixed(2)}%</span>
                    <span className="util-cell"><i><b style={{ width: `${utilization(market.supplied, market.borrowed)}%`, background: market.color }} /></i>{utilization(market.supplied, market.borrowed).toFixed(0)}%</span>
                    <span><button className="row-action" onClick={() => setModal({ action: 'Supply', market })}>操作</button></span>
                  </div>
                ))}
              </div>
              <button className="text-button" onClick={() => setActive('市場')}>查看全部市場 <ArrowUpRight size={15} /></button>
            </article>

            <article className="panel position-panel">
              <div className="panel-head"><div><h2>我的倉位</h2><p>{wallet ? `${wallet.name} · ${wallet.demo ? 'Demo session' : wallet.networkName}` : '連接錢包以查看倉位'}</p></div><Activity size={19} /></div>
              {wallet ? <>
                <div className="health-ring" style={{ '--score': Math.min(100, hf * 40) } as React.CSSProperties}><div><span>健康係數</span><strong>{hf.toFixed(2)}</strong><small>安全</small></div></div>
                <div className="position-stats"><div><span>抵押價值</span><b>{compactUsd(userCollateral)}</b></div><div><span>借款餘額</span><b>{compactUsd(userDebt)}</b></div><div><span>可借額度</span><b>{compactUsd(maxBorrow(userCollateral, 55) - userDebt)}</b></div></div>
                <div className="yield-note"><Sparkles size={18} /><div><b>ADA 抵押仍在工作</b><span>本期預估 PoS 收益 3.41% APY</span></div></div>
              </> : <div className="empty-position"><span><Wallet size={24} /></span><h3>掌握你的資本效率</h3><p>連接 Cardano 錢包，查看健康係數、收益與可借額度。</p><button className="primary wide" onClick={handleConnect}>連接錢包</button>{walletError && <small className="wallet-error">{walletError}</small>}</div>}
            </article>
          </section>

          <section className="panel staking-panel">
            <div className="panel-head staking-head">
              <div><span className="eyebrow">CARDIFI STAKE POOL OPERATOR</span><h2>CardFi 自營 ADA 鏈上質押池</h2><p>CardFi 運行自己的 Block Producer 與 Relay 基礎設施；用戶從錢包直接委託至 [CFI] Pool。</p></div>
              <div className="native-badges"><span>CardFi SPO</span><span>非託管</span><span>無鎖倉</span></div>
            </div>
            <div className="own-pool-grid">
              <article className="pool-card own-pool-card">
                <div className="pool-top"><span className="pool-logo">CF</span><div><b>[{cardFiPool.ticker}] {cardFiPool.name}</b><small>pool1…CARDIFI · Mainnet candidate</small></div><em><i />{cardFiPool.status}</em></div>
                <div className="pool-metrics"><div><span>ROA (30D)</span><strong className="positive">{cardFiPool.roa}%</strong></div><div><span>Saturation</span><strong>{cardFiPool.saturation}%</strong></div><div><span>Margin</span><strong>{cardFiPool.margin}%</strong></div><div><span>Pledge</span><strong>{cardFiPool.pledge}</strong></div></div>
                <div className="saturation-track"><i style={{ width: `${cardFiPool.saturation}%` }} /></div>
                <div className="pool-bottom"><span>Pool ID 與數據將由鏈上 indexer 驗證</span><button onClick={() => setStakeModal(cardFiPool)}>委託至 [CFI] <ArrowUpRight size={14} /></button></div>
              </article>
              <article className="operator-card">
                <div className="operator-head"><div><span className="eyebrow">OPERATOR STATUS</span><h3>池基礎設施</h3></div><Server size={19} /></div>
                <div className="node-list"><div><i className="planned" /><span>Block Producer</span><b>Config ready</b></div><div><i className="planned" /><span>Relay — Asia</span><b>Provision pending</b></div><div><i className="planned" /><span>Relay — Europe</span><b>Provision pending</b></div><div><i className="warning" /><span>KES Rotation</span><b>After deployment</b></div></div>
              </article>
            </div>
            <div className="staking-explainer"><b>CardFi 同時是協議方與 SPO：</b><span>借貸抵押由 Aiken 合約處理；[CFI] Stake Pool 則由獨立 Cardano node 基礎設施產塊。用戶委託不移轉 ADA；池固定成本與 margin 是 SPO 收入，委託者獎勵由 Cardano 帳本分配。</span></div>
          </section>

          <section className="feature-grid">
            <article className="feature-card flash-card">
              <div className="feature-icon"><Zap size={20} /></div><div><span className="eyebrow">ATOMIC FLASH LOANS</span><h3>零抵押，單筆原子執行</h3><p>借出、套利、清算與償還在同一筆 eUTXO 交易中完成。</p></div>
              <button onClick={() => setModal({ action: 'Flash', market: markets[0] })}>開啟 Flash Lab <ArrowUpRight size={16} /></button>
            </article>
            <article className="feature-card">
              <div className="feature-icon violet"><Code2 size={20} /></div><div><span className="eyebrow">SMART VAULT HOOKS</span><h3>策略，可以被組合</h3><p>槓桿農場、自動還債與清算防禦，全部受到鏈上風險邊界約束。</p></div>
              <button onClick={() => setActive('Vault Hooks')}>探索 Hooks <ArrowUpRight size={16} /></button>
            </article>
          </section>
          </div>

          <footer><span>CardFi Interactive Showcase · v0.2.0 · Deterministic demo data</span><div><a href="#risk">風險揭露</a><a href="#terms">條款</a><a href="https://github.com/doki03164/CARDFI">GitHub</a></div></footer>
        </div>
      </main>
      {mobileNav && <div className="nav-backdrop" onClick={() => setMobileNav(false)} />}
      {modal && <ActionModal action={modal.action} market={modal.market} onClose={() => setModal(null)} onSubmit={handleDemoSubmit} />}
      {stakeModal && <StakeModal pool={stakeModal} onClose={() => setStakeModal(null)} onSubmit={handleDemoSubmit} />}
    </div>
  );
}

export default App;
