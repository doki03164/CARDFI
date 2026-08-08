import { describe, expect, it } from 'vitest'
import { tr } from './i18n'

describe('CardFi i18n', () => {
  it('preserves Traditional Chinese in zh-TW mode', () => {
    expect(tr('zh-TW', '借貸市場')).toBe('借貸市場')
  })

  it('translates registered interface copy to English', () => {
    expect(tr('en', '市場')).toBe('Markets')
    expect(tr('en', 'ADA 鏈上質押')).toBe('ADA Staking')
  })

  it('passes through identifiers and unknown text', () => {
    expect(tr('en', 'ADA')).toBe('ADA')
    expect(tr('en', 'CardFi')).toBe('CardFi')
  })
})
