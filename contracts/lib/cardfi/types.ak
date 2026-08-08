use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{AssetName}

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
  Borrow {
    amount: Int,
    collateral_amount: Int,
    ltv_bps: Int,
    position_name: AssetName,
  }
  Repay { amount: Int, position_name: AssetName }
  Liquidate {
    repay_amount: Int,
    collateral_seized: Int,
    position_name: AssetName,
  }
  FlashExecute { principal: Int, fee_paid: Int }
}

/// Price is expressed as debt-asset units per collateral unit using an exact
/// rational number. The validity window uses POSIX milliseconds.
pub type OracleDatum {
  price_numerator: Int,
  price_denominator: Int,
  valid_from: Int,
  valid_until: Int,
  sequence: Int,
}

pub type PositionDatum {
  owner: VerificationKeyHash,
  collateral_amount: Int,
  debt_amount: Int,
  nonce: Int,
}

pub type PositionAction {
  Adjust { collateral_delta: Int, debt_delta: Int }
  LiquidatePosition { repay_amount: Int, collateral_seized: Int }
}
