import { describe, expect, it } from 'vitest';
import { flashFee, healthFactor, maxBorrow, utilization } from './protocol';

describe('CardFi protocol math', () => {
  it('calculates bounded utilization', () => {
    expect(utilization(100, 45)).toBe(45);
    expect(utilization(0, 10)).toBe(0);
    expect(utilization(100, 120)).toBe(100);
  });
  it('calculates health factor and debt-free infinity', () => {
    expect(healthFactor(1000, 500, 0.65)).toBe(1.3);
    expect(healthFactor(1000, 0)).toBe(Infinity);
  });
  it('calculates borrow limits and flash fee', () => {
    expect(maxBorrow(1000, 55)).toBe(550);
    expect(flashFee(100_000, 7)).toBe(70);
  });
});
