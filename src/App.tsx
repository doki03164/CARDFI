import { useMemo, useState } from 'react';
import {
  Activity, ArrowDownLeft, ArrowUpRight, BarChart3, Bell, ChevronDown,
  CircleDollarSign, Code2, CreditCard, Droplets, ExternalLink, Gauge,
  Layers3, Menu, Orbit, Search, Server, ShieldCheck, Sparkles, Wallet, X, Zap,
} from 'lucide-react';
import { compactUsd, flashFee, healthFactor, markets, maxBorrow, utilization, type Market } from './lib/protocol';
import { connectCardanoWallet, shortAddress, type WalletSession } from './lib/cardano';

type Action = 'Supply' | 'Borrow' | 'Flash';

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

function ActionModal({ action, market, onClose }: { action: Action; market: Market; onClose: () => void }) {
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
        <button className="primary wide" onClick={onClose}>{buttonLabel}<ArrowUpRight size={17} /></button>
        <p className="demo-note">Demo 模式｜尚未連接 Cardano 測試網</p>
      </section>
    </div>
  );
}

function StakeModal({ pool, onClose }: { pool: StakePool; onClose: () => void }) {
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
        <button className="primary wide" onClick={onClose}>建立鏈上委託交易<ArrowUpRight size={17} /></button>
        <p className="demo-note">Demo 模式｜正式版將透過 CIP-30 錢包簽署委託憑證</p>
      </section>
    </div>
  );
}

function App() {
  const [active, setActive] = useState('總覽');
  const [wallet, setWallet] = useState<WalletSession | null>(null);
  const [walletError, setWalletError] = useState('');
  const [mobileNav, setMobileNav] = useState(false);
  const [modal, setModal] = useState<{ action: Action; market: Market } | null>(null);
  const [stakeModal, setStakeModal] = useState<StakePool | null>(null);
  const [query, setQuery] = useState('');

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
          <div className="status-pill"><i /> All systems operational</div>
          <div className="header-actions">
            <button className="icon-button"><Bell size={18} /></button>
            <button className={`wallet-button ${wallet ? 'connected' : ''}`} onClick={handleConnect}>
              <Wallet size={17} />{wallet ? shortAddress(wallet.addressHex) : '連接錢包'}
            </button>
          </div>
        </header>

        <div className="content">
          <section className="hero-row">
            <div><span className="eyebrow">CARDANO LIQUIDITY LAYER</span><h1>早安，Builder<span className="dot">.</span></h1><p>讓抵押品持續產生收益，讓流動性無縫移動。</p></div>
            <div className="hero-actions">
              <button className="secondary" onClick={() => setModal({ action: 'Supply', market: markets[0] })}><ArrowDownLeft size={17} />供應資產</button>
              <button className="primary" onClick={() => setModal({ action: 'Borrow', market: markets[1] })}><ArrowUpRight size={17} />借入資產</button>
            </div>
          </section>

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

          <footer><span>CardFi Testnet Preview · v0.1.0</span><div><a href="#risk">風險揭露</a><a href="#terms">條款</a><a href="#github">GitHub</a></div></footer>
        </div>
      </main>
      {mobileNav && <div className="nav-backdrop" onClick={() => setMobileNav(false)} />}
      {modal && <ActionModal action={modal.action} market={modal.market} onClose={() => setModal(null)} />}
      {stakeModal && <StakeModal pool={stakeModal} onClose={() => setStakeModal(null)} />}
    </div>
  );
}

export default App;
