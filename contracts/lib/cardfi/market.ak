use aiken/interval.{Interval}
use cardfi/types

/// Solvency-shaped structural constraints shared by every transition.
pub fn valid_state(state: types.MarketDatum) -> Bool {
  and {
    state.supplied >= 0,
    state.borrowed >= 0,
    state.borrowed <= state.supplied,
    state.reserve >= 0,
    state.fee_bps >= 0,
    state.fee_bps <= 10_000,
    state.nonce >= 0,
  }
}

/// Validate arithmetic and risk bounds before inspecting transaction outputs.
pub fn valid_action(
  previous: types.MarketDatum,
  action: types.MarketAction,
) -> Bool {
  when action is {
    types.Supply { amount } -> amount > 0

    types.Withdraw { amount } ->
      amount > 0 && amount <= previous.supplied - previous.borrowed

    types.Borrow { amount, collateral_amount, ltv_bps, .. } ->
      amount > 0 && collateral_amount > 0 && ltv_bps > 0 && ltv_bps < 10_000 && amount <= previous.supplied - previous.borrowed

    types.Repay { amount, .. } -> amount > 0 && amount <= previous.borrowed

    types.FlashExecute { principal, fee_paid } ->
      principal > 0 && principal <= previous.supplied - previous.borrowed && fee_paid * 10_000 >= principal * previous.fee_bps
  }
}

/// Bind a borrow to an authenticated, finite-lived oracle reference input.
/// The inequality avoids division and therefore rounding ambiguity:
/// debt × 10_000 × denominator <= collateral × numerator × LTV_bps.
pub fn valid_oracle_borrow(
  action: types.MarketAction,
  oracle: types.OracleDatum,
  validity_range: Interval,
) -> Bool {
  when action is {
    types.Borrow { amount, collateral_amount, ltv_bps, .. } -> and {
        oracle.price_numerator > 0,
        oracle.price_denominator > 0,
        oracle.valid_from < oracle.valid_until,
        oracle.sequence >= 0,
        interval.between(oracle.valid_from, oracle.valid_until)
          |> interval.includes(validity_range),
        amount * 10_000 * oracle.price_denominator <= collateral_amount * oracle.price_numerator * ltv_bps,
      }

    _ -> True
  }
}

/// The exact state expected in the unique continuing market output.
pub fn next_state(
  previous: types.MarketDatum,
  action: types.MarketAction,
) -> types.MarketDatum {
  when action is {
    types.Supply { amount } ->
      types.MarketDatum {
        ..previous,
        supplied: previous.supplied + amount,
        nonce: previous.nonce + 1,
      }

    types.Withdraw { amount } ->
      types.MarketDatum {
        ..previous,
        supplied: previous.supplied - amount,
        nonce: previous.nonce + 1,
      }

    types.Borrow { amount, .. } ->
      types.MarketDatum {
        ..previous,
        borrowed: previous.borrowed + amount,
        nonce: previous.nonce + 1,
      }

    types.Repay { amount, .. } ->
      types.MarketDatum {
        ..previous,
        borrowed: previous.borrowed - amount,
        nonce: previous.nonce + 1,
      }

    types.FlashExecute { fee_paid, .. } ->
      types.MarketDatum {
        ..previous,
        reserve: previous.reserve + fee_paid,
        nonce: previous.nonce + 1,
      }
  }
}

/// Required delta of the market asset between the consumed shard and its
/// unique continuing output. Flash principal returns atomically, so only its
/// fee remains as a positive pool delta.
pub fn pool_delta(action: types.MarketAction) -> Int {
  when action is {
    types.Supply { amount } -> amount
    types.Withdraw { amount } -> 0 - amount
    types.Borrow { amount, .. } -> 0 - amount
    types.Repay { amount, .. } -> amount
    types.FlashExecute { fee_paid, .. } -> fee_paid
  }
}

/// Borrow and repay must atomically advance the uniquely identified position.
/// The collateral amount carried by Borrow is also bound to the consumed
/// position, preventing a caller from quoting unrelated collateral to the
/// oracle/LTV check.
pub fn valid_position_sync(
  action: types.MarketAction,
  previous: types.PositionDatum,
  next: types.PositionDatum,
) -> Bool {
  when action is {
    types.Borrow { amount, collateral_amount, .. } -> and {
        next.owner == previous.owner,
        previous.collateral_amount == collateral_amount,
        next.collateral_amount == previous.collateral_amount,
        next.debt_amount == previous.debt_amount + amount,
        next.nonce == previous.nonce + 1,
      }

    types.Repay { amount, .. } -> and {
        amount <= previous.debt_amount,
        next.owner == previous.owner,
        next.collateral_amount == previous.collateral_amount,
        next.debt_amount == previous.debt_amount - amount,
        next.nonce == previous.nonce + 1,
      }

    _ -> True
  }
}

const fixture: types.MarketDatum =
  types.MarketDatum {
    supplied: 1_000_000,
    borrowed: 400_000,
    reserve: 10_000,
    fee_bps: 7,
    nonce: 4,
  }

const position_fixture: types.PositionDatum =
  types.PositionDatum {
    owner: #"11111111111111111111111111111111111111111111111111111111",
    collateral_amount: 500_000,
    debt_amount: 100_000,
    nonce: 3,
  }

test supply_transition_is_exact() {
  let action = types.Supply { amount: 100_000 }
  next_state(fixture, action) == types.MarketDatum {
    ..fixture,
    supplied: 1_100_000,
    nonce: 5,
  } && pool_delta(action) == 100_000
}

test insolvent_state_fails() {
  !valid_state(types.MarketDatum { ..fixture, borrowed: 1_000_001 })
}

test borrow_transition_respects_ltv() {
  let action = types.Borrow {
    amount: 200_000,
    collateral_amount: 500_000,
    ltv_bps: 5_000,
    position_name: #"01",
  }
  valid_action(fixture, action) && next_state(fixture, action) == types.MarketDatum {
    ..fixture,
    borrowed: 600_000,
    nonce: 5,
  } && pool_delta(action) == -200_000
}

test unavailable_liquidity_borrow_fails() {
  !valid_action(
    types.MarketDatum { ..fixture, borrowed: 900_000 },
    types.Borrow {
      amount: 200_000,
      collateral_amount: 500_000,
      ltv_bps: 5_000,
      position_name: #"01",
    },
  )
}

const oracle_fixture: types.OracleDatum =
  types.OracleDatum {
    price_numerator: 1,
    price_denominator: 1,
    valid_from: 1_000,
    valid_until: 2_000,
    sequence: 8,
  }

test fresh_oracle_borrow_passes() {
  valid_oracle_borrow(
    types.Borrow {
      amount: 250_000,
      collateral_amount: 500_000,
      ltv_bps: 5_000,
      position_name: #"01",
    },
    oracle_fixture,
    interval.between(1_200, 1_300),
  )
}

test over_ltv_oracle_borrow_fails() {
  !valid_oracle_borrow(
    types.Borrow {
      amount: 250_001,
      collateral_amount: 500_000,
      ltv_bps: 5_000,
      position_name: #"01",
    },
    oracle_fixture,
    interval.between(1_200, 1_300),
  )
}

test stale_oracle_borrow_fails() {
  !valid_oracle_borrow(
    types.Borrow {
      amount: 250_000,
      collateral_amount: 500_000,
      ltv_bps: 5_000,
      position_name: #"01",
    },
    oracle_fixture,
    interval.between(2_100, 2_200),
  )
}

test flash_transition_collects_only_fee() {
  let action = types.FlashExecute { principal: 100_000, fee_paid: 70 }
  valid_action(fixture, action) && next_state(fixture, action) == types.MarketDatum {
    ..fixture,
    reserve: 10_070,
    nonce: 5,
  } && pool_delta(action) == 70
}

test borrow_position_sync_is_exact() {
  valid_position_sync(
    types.Borrow {
      amount: 200_000,
      collateral_amount: 500_000,
      ltv_bps: 5_000,
      position_name: #"01",
    },
    position_fixture,
    types.PositionDatum { ..position_fixture, debt_amount: 300_000, nonce: 4 },
  )
}

test mismatched_repay_position_debt_fails() {
  !valid_position_sync(
    types.Repay { amount: 50_000, position_name: #"01" },
    position_fixture,
    types.PositionDatum { ..position_fixture, debt_amount: 60_000, nonce: 4 },
  )
}
