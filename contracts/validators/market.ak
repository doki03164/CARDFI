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

    let oracle_is_valid = when redeemer is {
      types.Borrow { .. } -> {
        expect [oracle_input] = tx.reference_inputs
          |> list.filter(
              fn(input) {
                assets.has_nft(input.output.value, oracle_policy, oracle_name)
              },
            )
        expect transaction.InlineDatum(oracle_data) = oracle_input.output.datum
        expect oracle: types.OracleDatum = oracle_data
        market_logic.valid_oracle_borrow(redeemer, oracle, tx.validity_range)
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
    }
  }

  else(_) {
    fail
  }
}
