use aiken/collection/list
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use cardfi/market as market_logic
use cardfi/position as position_logic
use cardfi/types

/// Owner-controlled position state thread with atomic market/debt synchronization.
validator position(
  position_policy: PolicyId,
  position_name: AssetName,
  collateral_policy: PolicyId,
  collateral_name: AssetName,
  market_policy: PolicyId,
  market_asset: AssetName,
  shard_policy: PolicyId,
  shard_name: AssetName,
  oracle_policy: PolicyId,
  oracle_name: AssetName,
  governance_policy: PolicyId,
  governance_name: AssetName,
) {
  spend(
    datum: Option<types.PositionDatum>,
    redeemer: types.PositionAction,
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
              position_policy,
              position_name,
            )
          },
        )

    expect transaction.InlineDatum(next_data) = continuing_output.datum
    expect next: types.PositionDatum = next_data

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

    let expected = position_logic.next_state(previous, redeemer)

    let collateral_delta = when redeemer is {
      types.Adjust { collateral_delta, .. } -> collateral_delta
      types.LiquidatePosition { collateral_seized, .. } -> 0 - collateral_seized
    }
    let debt_delta = when redeemer is {
      types.Adjust { debt_delta, .. } -> debt_delta
      types.LiquidatePosition { repay_amount, .. } -> 0 - repay_amount
    }
    let owner_is_authorized = when redeemer is {
      types.Adjust { .. } -> list.has(tx.extra_signatories, previous.owner)
      types.LiquidatePosition { .. } -> True
    }

    let liquidation_is_valid = when redeemer is {
      types.LiquidatePosition { repay_amount, collateral_seized } -> {
        expect [oracle_input] = tx.reference_inputs
          |> list.filter(
              fn(input) {
                assets.has_nft(input.output.value, oracle_policy, oracle_name)
              },
            )
        expect transaction.InlineDatum(oracle_data) = oracle_input.output.datum
        expect oracle: types.OracleDatum = oracle_data
        market_logic.valid_liquidation(
          types.Liquidate { repay_amount, collateral_seized, position_name },
          previous,
          oracle,
          tx.validity_range,
          governance.liquidation_threshold_bps,
          governance.close_factor_bps,
          governance.liquidation_bonus_bps,
        )
      }

      _ -> True
    }

    let market_is_synced = if debt_delta == 0 {
      True
    } else {
      expect [market_input] = tx.inputs
        |> list.filter(
            fn(input) {
              assets.has_nft(input.output.value, shard_policy, shard_name)
            },
          )
      expect transaction.InlineDatum(market_data) = market_input.output.datum
      expect market_previous: types.MarketDatum = market_data
      expect [market_output] = tx.outputs
        |> list.filter(
            fn(output) {
              output.address == market_input.output.address && assets.has_nft(
                output.value,
                shard_policy,
                shard_name,
              )
            },
          )
      expect transaction.InlineDatum(market_next_data) = market_output.datum
      expect market_next: types.MarketDatum = market_next_data
      let market_asset_delta = assets.quantity_of(
        market_output.value,
        market_policy,
        market_asset,
      ) - assets.quantity_of(
        market_input.output.value,
        market_policy,
        market_asset,
      )
      position_logic.valid_market_sync(
        market_previous,
        market_next,
        debt_delta,
        market_asset_delta,
      )
    }

    and {
      owner_is_authorized,
      assets.has_nft(own_input.output.value, position_policy, position_name),
      assets.quantity_of(
        continuing_output.value,
        collateral_policy,
        collateral_name,
      ) == assets.quantity_of(
        own_input.output.value,
        collateral_policy,
        collateral_name,
      ) + collateral_delta,
      next == expected,
      next.owner == previous.owner,
      position_logic.valid_state(previous),
      position_logic.valid_state(next),
      market_is_synced,
      liquidation_is_valid,
    }
  }

  else(_) {
    fail
  }
}
