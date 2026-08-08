use aiken/collection/list
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use cardfi/position as position_logic
use cardfi/types

/// Owner-controlled position state thread. Market/debt synchronization is
/// intentionally separated from this ownership and value-preservation layer.
validator position(
  position_policy: PolicyId,
  position_name: AssetName,
  collateral_policy: PolicyId,
  collateral_name: AssetName,
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

    let expected = position_logic.next_state(previous, redeemer)

    when redeemer is {
      types.Adjust { collateral_delta, .. } -> and {
          list.has(tx.extra_signatories, previous.owner),
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
        }
    }
  }

  else(_) {
    fail
  }
}
