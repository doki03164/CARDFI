use cardfi/types

pub fn valid_state(position: types.PositionDatum) -> Bool {
  and {
    position.collateral_amount >= 0,
    position.debt_amount >= 0,
    position.nonce >= 0,
  }
}

pub fn next_state(
  previous: types.PositionDatum,
  action: types.PositionAction,
) -> types.PositionDatum {
  when action is {
    types.Adjust { collateral_delta, debt_delta } ->
      types.PositionDatum {
        ..previous,
        collateral_amount: previous.collateral_amount + collateral_delta,
        debt_amount: previous.debt_amount + debt_delta,
        nonce: previous.nonce + 1,
      }

    types.LiquidatePosition { repay_amount, collateral_seized } ->
      types.PositionDatum {
        ..previous,
        collateral_amount: previous.collateral_amount - collateral_seized,
        debt_amount: previous.debt_amount - repay_amount,
        nonce: previous.nonce + 1,
      }
  }
}

/// A debt adjustment is valid only when the market shard advances by the same
/// debt delta and the underlying market asset moves in the opposite direction.
pub fn valid_market_sync(
  previous: types.MarketDatum,
  next: types.MarketDatum,
  debt_delta: Int,
  market_asset_delta: Int,
) -> Bool {
  and {
    next.supplied == previous.supplied,
    next.borrowed == previous.borrowed + debt_delta,
    next.reserve == previous.reserve,
    next.fee_bps == previous.fee_bps,
    next.nonce == previous.nonce + 1,
    market_asset_delta == 0 - debt_delta,
  }
}

const fixture: types.PositionDatum =
  types.PositionDatum {
    owner: #"11111111111111111111111111111111111111111111111111111111",
    collateral_amount: 1_000_000,
    debt_amount: 300_000,
    nonce: 2,
  }

test owner_adjustment_is_exact() {
  let next = next_state(
    fixture,
    types.Adjust { collateral_delta: 100_000, debt_delta: 20_000 },
  )
  next == types.PositionDatum {
    ..fixture,
    collateral_amount: 1_100_000,
    debt_amount: 320_000,
    nonce: 3,
  } && valid_state(next)
}

test negative_collateral_position_fails() {
  let next = next_state(
    fixture,
    types.Adjust { collateral_delta: -1_000_001, debt_delta: 0 },
  )
  !valid_state(next)
}

test liquidation_position_transition_is_exact() {
  next_state(
    fixture,
    types.LiquidatePosition {
      repay_amount: 100_000,
      collateral_seized: 120_000,
    },
  ) == types.PositionDatum {
    ..fixture,
    collateral_amount: 880_000,
    debt_amount: 200_000,
    nonce: 3,
  }
}

const market_fixture: types.MarketDatum =
  types.MarketDatum {
    supplied: 1_000_000,
    borrowed: 300_000,
    reserve: 10_000,
    fee_bps: 7,
    nonce: 4,
  }

test market_sync_matches_debt_increase_and_asset_outflow() {
  valid_market_sync(
    market_fixture,
    types.MarketDatum { ..market_fixture, borrowed: 400_000, nonce: 5 },
    100_000,
    -100_000,
  )
}

test market_sync_rejects_repay_without_asset_inflow() {
  !valid_market_sync(
    market_fixture,
    types.MarketDatum { ..market_fixture, borrowed: 250_000, nonce: 5 },
    -50_000,
    0,
  )
}
