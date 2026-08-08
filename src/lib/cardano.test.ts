import { describe, expect, it } from 'vitest';
import { discoverWallets, shortAddress } from './cardano';

describe('CIP-30 wallet adapter', () => {
  it('discovers supported providers in deterministic preference order', () => {
    const enable = async () => ({}) as never;
    const found = discoverWallets({ eternl: { name: 'Eternl', enable }, lace: { name: 'Lace', enable } });
    expect(found.map((wallet) => wallet.key)).toEqual(['lace', 'eternl']);
  });

  it('shortens long CBOR address strings', () => {
    expect(shortAddress('0123456789abcdefghijkl')).toBe('0123456…hijkl');
    expect(shortAddress('addr1short')).toBe('addr1short');
  });
});
