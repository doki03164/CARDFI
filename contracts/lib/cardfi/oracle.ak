use aiken/interval.{Interval}
use cardfi/types

pub fn valid_datum(oracle: types.OracleDatum) -> Bool {
  and {
    oracle.price_numerator > 0,
    oracle.price_denominator > 0,
    oracle.valid_from < oracle.valid_until,
    oracle.sequence >= 0,
  }
}

pub fn valid_update(
  previous: types.OracleDatum,
  next: types.OracleDatum,
  validity_range: Interval,
) -> Bool {
  and {
    valid_datum(previous),
    valid_datum(next),
    next.sequence == previous.sequence + 1,
    next.valid_from >= previous.valid_from,
    next.valid_until > previous.valid_until,
    interval.between(next.valid_from, next.valid_until)
      |> interval.includes(validity_range),
  }
}

const previous: types.OracleDatum =
  types.OracleDatum {
    price_numerator: 74,
    price_denominator: 100,
    valid_from: 1_000,
    valid_until: 2_000,
    sequence: 10,
  }

test sequential_oracle_update_passes() {
  valid_update(
    previous,
    types.OracleDatum {
      price_numerator: 75,
      price_denominator: 100,
      valid_from: 1_900,
      valid_until: 3_000,
      sequence: 11,
    },
    interval.between(2_100, 2_200),
  )
}

test skipped_oracle_sequence_fails() {
  !valid_update(
    previous,
    types.OracleDatum {
      price_numerator: 75,
      price_denominator: 100,
      valid_from: 1_900,
      valid_until: 3_000,
      sequence: 12,
    },
    interval.between(2_100, 2_200),
  )
}
