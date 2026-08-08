use aiken/collection/list
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use cardfi/market as market_logic
use cardfi/types

/// CardFi market state-transition validator.
///
/// This first implementation isolates arithmetic invariants so they can be
/// property-tested before value-level shard NFT and oracle checks are added.
validator market(
  market_policy: PolicyId,
  market_asset: AssetName,
  shard_policy: PolicyId,
  shard_name: AssetName,
  oracle_policy: PolicyId,
  oracle_name: AssetName,
  position_policy: PolicyId,
  governance_policy: PolicyId,
  governance_name: AssetName,
) {
  spend(
    datum: Option<types.MarketDatum>,
    redeemer: types.MarketAction,
    own_ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(previous) = datum

    expect Some(own_input) = tx.inputs
      |> list.find(fn(input) { input.output_reference == own_ref })

    expect [continuing_output] = tx.outputs
      |> list.filter(
          fn(output) {
            output.address == own_input.output.address && assets.has_nft(
              output.value,
              shard_policy,
              shard_name,
            )
          },
        )

    expect transaction.InlineDatum(next_data) = continuing_output.datum
    expect next: types.MarketDatum = next_data

    expect [governance_input] = tx.reference_inputs
      |> list.filter(
          fn(input) {
            assets.has_nft(
              input.output.value,
              governance_policy,
              governance_name,
            )
          },
        )
    expect transaction.InlineDatum(governance_data) = governance_input.output.datum
    expect governance: types.GovernanceDatum = governance_data

    let oracle_is_valid = when redeemer is {
      types.Borrow { ltv_bps, .. } -> {
        expect [oracle_input] = tx.reference_inputs
          |> list.filter(
              fn(input) {
                assets.has_nft(input.output.value, oracle_policy, oracle_name)
              },
            )
        expect transaction.InlineDatum(oracle_data) = oracle_input.output.datum
        expect oracle: types.OracleDatum = oracle_data
        ltv_bps <= governance.max_ltv_bps && market_logic.valid_oracle_borrow(
          redeemer,
          oracle,
          tx.validity_range,
        )
      }

      _ -> True
    }

    let position_is_synced = when redeemer is {
      types.Borrow { position_name, .. } -> {
        expect [position_input] = tx.inputs
          |> list.filter(
              fn(input) {
                assets.has_nft(
                  input.output.value,
                  position_policy,
                  position_name,
                )
              },
            )
        expect transaction.InlineDatum(position_data) = position_input.output.datum
        expect position_previous: types.PositionDatum = position_data
        expect [position_output] = tx.outputs
          |> list.filter(
              fn(output) {
                output.address == position_input.output.address && assets.has_nft(
                  output.value,
                  position_policy,
                  position_name,
                )
              },
            )
        expect transaction.InlineDatum(position_next_data) = position_output.datum
        expect position_next: types.PositionDatum = position_next_data
        and {
          list.has(tx.extra_signatories, position_previous.owner),
          market_logic.valid_position_sync(
            redeemer,
            position_previous,
            position_next,
          ),
        }
      }

      types.Repay { position_name, .. } -> {
        expect [position_input] = tx.inputs
          |> list.filter(
              fn(input) {
                assets.has_nft(
                  input.output.value,
                  position_policy,
                  position_name,
                )
              },
            )
        expect transaction.InlineDatum(position_data) = position_input.output.datum
        expect position_previous: types.PositionDatum = position_data
        expect [position_output] = tx.outputs
          |> list.filter(
              fn(output) {
                output.address == position_input.output.address && assets.has_nft(
                  output.value,
                  position_policy,
                  position_name,
                )
              },
            )
        expect transaction.InlineDatum(position_next_data) = position_output.datum
        expect position_next: types.PositionDatum = position_next_data
        and {
          list.has(tx.extra_signatories, position_previous.owner),
          market_logic.valid_position_sync(
            redeemer,
            position_previous,
            position_next,
          ),
        }
      }

      types.Liquidate { position_name, .. } -> {
        expect [position_input] = tx.inputs
          |> list.filter(
              fn(input) {
                assets.has_nft(
                  input.output.value,
                  position_policy,
                  position_name,
                )
              },
            )
        expect transaction.InlineDatum(position_data) = position_input.output.datum
        expect position_previous: types.PositionDatum = position_data
        expect [position_output] = tx.outputs
          |> list.filter(
              fn(output) {
                output.address == position_input.output.address && assets.has_nft(
                  output.value,
                  position_policy,
                  position_name,
                )
              },
            )
        expect transaction.InlineDatum(position_next_data) = position_output.datum
        expect position_next: types.PositionDatum = position_next_data
        expect [oracle_input] = tx.reference_inputs
          |> list.filter(
              fn(input) {
                assets.has_nft(input.output.value, oracle_policy, oracle_name)
              },
            )
        expect transaction.InlineDatum(oracle_data) = oracle_input.output.datum
        expect oracle: types.OracleDatum = oracle_data
        and {
          market_logic.valid_position_sync(
            redeemer,
            position_previous,
            position_next,
          ),
          market_logic.valid_liquidation(
            redeemer,
            position_previous,
            oracle,
            tx.validity_range,
            governance.liquidation_threshold_bps,
            governance.close_factor_bps,
            governance.liquidation_bonus_bps,
          ),
        }
      }

      _ -> True
    }

    and {
      assets.has_nft(own_input.output.value, shard_policy, shard_name),
      assets.quantity_of(continuing_output.value, market_policy, market_asset) == assets.quantity_of(
        own_input.output.value,
        market_policy,
        market_asset,
      ) + market_logic.pool_delta(redeemer),
      market_logic.valid_action(previous, redeemer),
      market_logic.valid_state(previous),
      market_logic.valid_state(next),
      next == market_logic.next_state(previous, redeemer),
      oracle_is_valid,
      position_is_synced,
    }
  }

  else(_) {
    fail
  }
}
