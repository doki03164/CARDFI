use cardano/transaction.{OutputReference, Transaction}
use cardfi/types

/// CardFi market state-transition validator.
///
/// This first implementation isolates arithmetic invariants so they can be
/// property-tested before value-level shard NFT and oracle checks are added.
validator market {
  spend(
    datum: Option<types.MarketDatum>,
    redeemer: types.MarketAction,
    _own_ref: OutputReference,
    _tx: Transaction,
  ) {
    expect Some(previous) = datum

    when redeemer is {
      types.Supply { amount } -> amount > 0 && previous.supplied >= 0

      types.Withdraw { amount } ->
        amount > 0 && amount <= previous.supplied - previous.borrowed

      types.Borrow { amount, collateral_value, ltv_bps } ->
        amount > 0 && ltv_bps > 0 && ltv_bps < 10_000 && amount * 10_000 <= collateral_value * ltv_bps && amount <= previous.supplied - previous.borrowed

      types.Repay { amount } -> amount > 0 && amount <= previous.borrowed

      types.FlashExecute { principal, fee_paid } ->
        principal > 0 && principal <= previous.supplied - previous.borrowed && fee_paid * 10_000 >= principal * previous.fee_bps
    }
  }

  else(_) {
    fail
  }
}

test flash_fee_invariant() {
  let principal = 100_000
  let fee_bps = 7
  let paid = 70
  paid * 10_000 >= principal * fee_bps
}

test underpaid_flash_fee_fails() fail {
  let principal = 100_000
  let fee_bps = 7
  let paid = 69
  expect paid * 10_000 >= principal * fee_bps
}
