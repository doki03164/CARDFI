pub type MarketDatum {
  MarketDatum {
    supplied: Int,
    borrowed: Int,
    reserve: Int,
    fee_bps: Int,
    nonce: Int,
  }
}

pub type MarketAction {
  Supply { amount: Int }
  Withdraw { amount: Int }
  Borrow { amount: Int, collateral_value: Int, ltv_bps: Int }
  Repay { amount: Int }
  FlashExecute { principal: Int, fee_paid: Int }
}
