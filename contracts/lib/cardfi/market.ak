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

    types.Borrow { amount, collateral_value, ltv_bps } ->
      amount > 0
        && ltv_bps > 0
        && ltv_bps < 10_000
        && amount * 10_000 <= collateral_value * ltv_bps
        && amount <= previous.supplied - previous.borrowed

    types.Repay { amount } -> amount > 0 && amount <= previous.borrowed

    types.FlashExecute { principal, fee_paid } ->
      principal > 0
        && principal <= previous.supplied - previous.borrowed
        && fee_paid * 10_000 >= principal * previous.fee_bps
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

    types.Repay { amount } ->
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
    types.Repay { amount } -> amount
    types.FlashExecute { fee_paid, .. } -> fee_paid
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

test supply_transition_is_exact() {
  let action = types.Supply { amount: 100_000 }
  next_state(fixture, action) ==
    types.MarketDatum { ..fixture, supplied: 1_100_000, nonce: 5 }
    && pool_delta(action) == 100_000
}

test insolvent_state_fails() {
  !valid_state(types.MarketDatum { ..fixture, borrowed: 1_000_001 })
}

test borrow_transition_respects_ltv() {
  let action =
    types.Borrow {
      amount: 200_000,
      collateral_value: 500_000,
      ltv_bps: 5_000,
    }
  valid_action(fixture, action)
    && next_state(fixture, action) ==
      types.MarketDatum { ..fixture, borrowed: 600_000, nonce: 5 }
    && pool_delta(action) == -200_000
}

test over_ltv_borrow_fails() {
  !valid_action(
    fixture,
    types.Borrow {
      amount: 300_000,
      collateral_value: 500_000,
      ltv_bps: 5_000,
    },
  )
}

test flash_transition_collects_only_fee() {
  let action = types.FlashExecute { principal: 100_000, fee_paid: 70 }
  valid_action(fixture, action)
    && next_state(fixture, action) ==
      types.MarketDatum { ..fixture, reserve: 10_070, nonce: 5 }
    && pool_delta(action) == 70
}
