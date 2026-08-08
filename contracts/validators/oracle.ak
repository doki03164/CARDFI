use aiken/collection/list
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use cardfi/oracle as oracle_logic
use cardfi/types

/// Publisher-controlled oracle state thread. The active publisher is resolved
/// from the Governance NFT reference input, enabling governed key rotation.
validator oracle(
  oracle_policy: PolicyId,
  oracle_name: AssetName,
  governance_policy: PolicyId,
  governance_name: AssetName,
) {
  spend(
    datum: Option<types.OracleDatum>,
    _redeemer: Data,
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
              oracle_policy,
              oracle_name,
            )
          },
        )

    expect transaction.InlineDatum(next_data) = continuing_output.datum
    expect next: types.OracleDatum = next_data

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

    and {
      list.has(tx.extra_signatories, governance.oracle_publisher),
      assets.has_nft(own_input.output.value, oracle_policy, oracle_name),
      oracle_logic.valid_update(previous, next, tx.validity_range),
    }
  }

  else(_) {
    fail
  }
}
