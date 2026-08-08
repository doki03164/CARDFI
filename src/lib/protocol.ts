export type AssetSymbol = 'ADA' | 'DJED' | 'iUSD' | 'MIN';

export interface Market {
  symbol: AssetSymbol;
  name: string;
  price: number;
  supplied: number;
  borrowed: number;
  supplyApr: number;
  borrowApr: number;
  ltv: number;
  color: string;
}

export const markets: Market[] = [
  { symbol: 'ADA', name: 'Cardano', price: 0.74, supplied: 128_420_000, borrowed: 57_780_000, supplyApr: 3.82, borrowApr: 5.46, ltv: 55, color: '#15d39a' },
  { symbol: 'DJED', name: 'Djed', price: 1, supplied: 18_670_000, borrowed: 11_290_000, supplyApr: 4.94, borrowApr: 7.21, ltv: 70, color: '#d6ff62' },
  { symbol: 'iUSD', name: 'Indigo USD', price: 0.99, supplied: 9_840_000, borrowed: 4_130_000, supplyApr: 4.26, borrowApr: 6.88, ltv: 68, color: '#83a7ff' },
  { symbol: 'MIN', name: 'Minswap', price: 0.028, supplied: 84_300_000, borrowed: 18_200_000, supplyApr: 2.17, borrowApr: 8.65, ltv: 35, color: '#c58cff' },
];

export function utilization(supplied: number, borrowed: number) {
  if (supplied <= 0) return 0;
  return Math.min(100, Math.max(0, (borrowed / supplied) * 100));
}

export function healthFactor(collateralUsd: number, debtUsd: number, liquidationThreshold = 0.65) {
  if (debtUsd <= 0) return Number.POSITIVE_INFINITY;
  return (collateralUsd * liquidationThreshold) / debtUsd;
}

export function maxBorrow(collateralUsd: number, ltvPercent: number) {
  return collateralUsd * (ltvPercent / 100);
}

export function flashFee(amount: number, feeBps = 7) {
  return amount * (feeBps / 10_000);
}

export function compactUsd(value: number) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact', maximumFractionDigits: 2 }).format(value);
}
