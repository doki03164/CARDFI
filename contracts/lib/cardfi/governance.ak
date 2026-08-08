use cardfi/types

pub fn valid_datum(config: types.GovernanceDatum) -> Bool {
  and {
    config.max_ltv_bps > 0,
    config.max_ltv_bps < config.liquidation_threshold_bps,
    config.liquidation_threshold_bps < 10_000,
    config.close_factor_bps > 0,
    config.close_factor_bps <= 10_000,
    config.liquidation_bonus_bps >= 0,
    config.liquidation_bonus_bps < 10_000,
    config.sequence >= 0,
  }
}

pub fn valid_update(
  previous: types.GovernanceDatum,
  next: types.GovernanceDatum,
  action: types.GovernanceAction,
) -> Bool {
  and {
    valid_datum(previous),
    valid_datum(next),
    next.sequence == previous.sequence + 1,
    when action is {
      types.UpdateParameters -> next.admin == previous.admin
      types.RotateAdmin { new_admin } -> and {
          new_admin != previous.admin,
          next.admin == new_admin,
          next.oracle_publisher == previous.oracle_publisher,
          next.max_ltv_bps == previous.max_ltv_bps,
          next.liquidation_threshold_bps == previous.liquidation_threshold_bps,
          next.close_factor_bps == previous.close_factor_bps,
          next.liquidation_bonus_bps == previous.liquidation_bonus_bps,
        }
    },
  }
}

const previous: types.GovernanceDatum =
  types.GovernanceDatum {
    admin: #"11111111111111111111111111111111111111111111111111111111",
    oracle_publisher: #"22222222222222222222222222222222222222222222222222222222",
    max_ltv_bps: 7_000,
    liquidation_threshold_bps: 8_000,
    close_factor_bps: 5_000,
    liquidation_bonus_bps: 500,
    sequence: 4,
  }

test valid_parameter_update_passes() {
  valid_update(
    previous,
    types.GovernanceDatum { ..previous, max_ltv_bps: 6_500, sequence: 5 },
    types.UpdateParameters,
  )
}

test invalid_risk_ordering_fails() {
  !valid_update(
    previous,
    types.GovernanceDatum { ..previous, max_ltv_bps: 8_500, sequence: 5 },
    types.UpdateParameters,
  )
}

test oracle_publisher_rotation_is_a_parameter_update() {
  valid_update(
    previous,
    types.GovernanceDatum {
      ..previous,
      oracle_publisher: #"44444444444444444444444444444444444444444444444444444444",
      sequence: 5,
    },
    types.UpdateParameters,
  )
}

test dual_accepted_admin_rotation_passes_logic_gate() {
  valid_update(
    previous,
    types.GovernanceDatum {
      ..previous,
      admin: #"33333333333333333333333333333333333333333333333333333333",
      sequence: 5,
    },
    types.RotateAdmin {
      new_admin: #"33333333333333333333333333333333333333333333333333333333",
    },
  )
}

test admin_rotation_cannot_change_risk_parameters() {
  !valid_update(
    previous,
    types.GovernanceDatum {
      ..previous,
      admin: #"33333333333333333333333333333333333333333333333333333333",
      close_factor_bps: 6_000,
      sequence: 5,
    },
    types.RotateAdmin {
      new_admin: #"33333333333333333333333333333333333333333333333333333333",
    },
  )
}
