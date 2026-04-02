use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{ScriptHash}
use cardano/address.{Script, Script}
use cardano/assets.{PolicyId, PolicyId, has_nft, has_nft}
use cardano/script_context.{ScriptContext, ScriptContext}
use cardano/transaction.{
  Input, Output, Output, OutputReference, OutputReference, Redeemer,
  ScriptPurpose, Transaction, Transaction, Withdraw, Withdraw, placeholder,
}
use charms_cardano/beacon.{BeaconParts, beacon_asset_name}
use charms_cardano/test_utils.{
  test_beacon, test_beacon_parts, test_charms_version, test_schnorr_components,
}

fn main_impl(
  version_nft_policy_id: ScriptHash,
  version_nft_name: ByteArray,
  self: Transaction,
) -> Bool {
  expect Some(ref_input) = list.last(self.reference_inputs)
  expect
    has_nft(ref_input.output.value, version_nft_policy_id, version_nft_name)

  expect Some(charms_validator) = ref_input.output.reference_script

  self.redeemers |> pairs.has_key(Withdraw(Script(charms_validator)))
}

// redeemer is the beacon nft asset name
validator main(version_nft_policy_id: ScriptHash, _app_vk: ByteArray) {
  mint(redeemer: ByteArray, _policy_id: PolicyId, self: Transaction) {
    main_impl(version_nft_policy_id, redeemer, self)
  }

  spend(
    _datum_opt: Option<Data>,
    redeemer: ByteArray,
    _utxo: OutputReference,
    self: Transaction,
  ) {
    main_impl(version_nft_policy_id, redeemer, self)
  }

  else(_ctx: ScriptContext) {
    fail @"invalid script purpose"
  }
}

// test main_spend_pass() {
//   // downcast public values
//   let public_values: Data = base_passing_circuit().public_values
//   let app =
//     App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
//   let app_public_inputs = [Pair(app, public_values)]
//   let placeholder_data: Data = placeholder
//   let input_arg = base_passing_circuit().vk

test scrolls_main_pass() {
  // Use script hash instead of full validator bytecode
  let scrolls_sh = #"51d44678ebc1fe5a5dd58cafb3bcd31f0f5be1fc1de97e97deb1380c"

  // beacon output reference
  let ref_oref = OutputReference { output_index: 1, transaction_id: #"" }
  let ref_input =
    Input { output_reference: ref_oref, output: test_beacon(scrolls_sh) }
  let scrolls_redeemer: Redeemer = test_schnorr_components.signature

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [Pair(Withdraw(Script(scrolls_sh)), scrolls_redeemer)]

  let transaction =
    Transaction {
      ..placeholder,
      redeemers,
      reference_inputs: [ref_input],
      id: test_schnorr_components.message,
    }

  //   let redeemers: Pairs<ScriptPurpose, Redeemer> =
  //     [
  //       Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
  //       Pair(Spend(mock_outref), spell_redeemer),
  //     ]
  // Test the main_impl logic directly with the required parameters
  main.spend(
    test_beacon_parts.policy_id,
    // version_nft_policy_id (validator parameter)
    #"deadbeef",
    // _app_vk (validator parameter)
    None,
    // _datum_opt (spend function parameter)
    beacon_asset_name(test_beacon_parts, test_charms_version),
    // redeemer: ByteArray (spend function parameter)
    mock_outref,
    // _utxo (spend function parameter)
    transaction,
  )
  // self (spend function parameter)
}

test scrolls_main_impl_pass() {
  // Use script hash instead of full validator bytecode
  let scrolls_sh = #"51d44678ebc1fe5a5dd58cafb3bcd31f0f5be1fc1de97e97deb1380c"

  // beacon output reference
  let ref_oref = OutputReference { output_index: 1, transaction_id: #"" }
  let ref_input =
    Input { output_reference: ref_oref, output: test_beacon(scrolls_sh) }
  let scrolls_redeemer: Redeemer = test_schnorr_components.signature

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [Pair(Withdraw(Script(scrolls_sh)), scrolls_redeemer)]

  let transaction =
    Transaction {
      ..placeholder,
      redeemers,
      reference_inputs: [ref_input],
      id: test_schnorr_components.message,
    }

  // Test the main_impl logic directly with the required parameters
  main_impl(
    test_beacon_parts.policy_id,
    // version_nft_policy_id
    beacon_asset_name(test_beacon_parts, test_charms_version),
    // version_nft_name  
    transaction,
  )
  // self
}
