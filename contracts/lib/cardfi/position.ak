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
