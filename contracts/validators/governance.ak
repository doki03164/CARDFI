use aiken/collection/list
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use cardfi/governance as governance_logic
use cardfi/types

/// Governance state thread authenticated by a unique NFT. Parameter updates
/// require the current admin; admin rotation additionally requires acceptance
/// by the new admin key.
validator governance(governance_policy: PolicyId, governance_name: AssetName) {
  spend(
    datum: Option<types.GovernanceDatum>,
    redeemer: types.GovernanceAction,
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
              governance_policy,
              governance_name,
            )
          },
        )
    expect transaction.InlineDatum(next_data) = continuing_output.datum
    expect next: types.GovernanceDatum = next_data

    let new_admin_accepts = when redeemer is {
      types.RotateAdmin { new_admin } ->
        list.has(tx.extra_signatories, new_admin)
      _ -> True
    }

    and {
      assets.has_nft(own_input.output.value, governance_policy, governance_name),
      list.has(tx.extra_signatories, previous.admin),
      new_admin_accepts,
      governance_logic.valid_update(previous, next, redeemer),
    }
  }

  else(_) {
    fail
  }
}
