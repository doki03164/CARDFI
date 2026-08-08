export interface Cip30Api {
  getNetworkId(): Promise<number>;
  getUsedAddresses(): Promise<string[]>;
  getUnusedAddresses(): Promise<string[]>;
  getChangeAddress(): Promise<string>;
  getBalance(): Promise<string>;
  signTx(tx: string, partialSign?: boolean): Promise<string>;
  submitTx(tx: string): Promise<string>;
}

export interface Cip30WalletProvider {
  name: string;
  icon?: string;
  apiVersion?: string;
  enable(): Promise<Cip30Api>;
  isEnabled?(): Promise<boolean>;
}

declare global {
  interface Window {
    cardano?: Record<string, Cip30WalletProvider | undefined>;
  }
}

const preferredWallets = ['lace', 'nami', 'eternl', 'vespr', 'flint', 'typhoncip30'];

export interface WalletSession {
  key: string;
  name: string;
  networkId: number;
  networkName: 'Mainnet' | 'Testnet';
  addressHex: string;
  api: Cip30Api | null;
  demo: boolean;
}

export function discoverWallets(cardano = window.cardano) {
  if (!cardano) return [];
  return preferredWallets
    .filter((key) => cardano[key]?.enable)
    .map((key) => ({ key, provider: cardano[key]! }));
}

export function shortAddress(address: string) {
  if (address.length <= 14) return address;
  return `${address.slice(0, 7)}…${address.slice(-5)}`;
}

export async function connectCardanoWallet(): Promise<WalletSession> {
  const [installed] = discoverWallets();
  if (!installed) {
    return { key: 'demo', name: 'Demo Wallet', networkId: 0, networkName: 'Testnet', addressHex: 'addr_test1…demo9', api: null, demo: true };
  }

  const api = await installed.provider.enable();
  const networkId = await api.getNetworkId();
  const used = await api.getUsedAddresses();
  const addressHex = used[0] || (await api.getChangeAddress());
  return {
    key: installed.key,
    name: installed.provider.name || installed.key,
    networkId,
    networkName: networkId === 1 ? 'Mainnet' : 'Testnet',
    addressHex,
    api,
    demo: false,
  };
}
