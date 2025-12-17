use aiken/builtin.{verify_schnorr_secp256k1_signature}
use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Address, Credential, Script}
use cardano/assets.{PolicyId, from_asset, has_nft}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{
  InlineDatum, NoDatum, Output, OutputReference, Redeemer, ScriptPurpose,
  Spend, Transaction, Withdraw, placeholder,
}
use charms_cardano/beacon.{BeaconParts}
use charms_cardano/charms.{
  App, NormalizedSpell, cbor_serialize,
}
use charms_cardano/test_utils.{
  TestCircuit, base_passing_circuit, test_beacon_parts,
}
use aiken/crypto.{ScriptHash}

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

validator scrolls(vkey: ByteArray) {
  withdraw(redeemer: ByteArray, _account: Credential, self: Transaction) {
    verify_schnorr_secp256k1_signature(vkey, self.id, redeemer)
  }

  else(_ctx: ScriptContext) {
    fail @"invalid script purpose"
  }
}

test main_spend_pass() {
  // downcast public values
  let public_values: Data = base_passing_circuit().public_values
  let app =
    App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
  let app_public_inputs = [Pair(app, public_values)]
  let placeholder_data: Data = placeholder
  let input_arg = base_passing_circuit().vk

  // Create a mock spell and spell datum
  let spell: NormalizedSpell =
    NormalizedSpell {
      version: 1,
      tx: placeholder_data,
      app_public_inputs,
      mock: True,
    }

  // Add other required fields based on your NormalizedSpell definition
  let spell_datum: Data = NoDatum

  // Create mock spell redeemer
  let spell_redeemer: Redeemer = "8"

  // Create mock transaction with required outputs
  let mock_output =
    Output {
      address: Address {
        payment_credential: Script(base_passing_circuit().sh),
        stake_credential: None,
      },
      value: from_asset(#"", #"", 100),
      datum: InlineDatum(spell_datum),
      reference_script: None,
    }

  let mock_outref = OutputReference { transaction_id: #"", output_index: 0 }

  let expected_public_values: List<Int> =
    cbor_serialize(base_passing_circuit().vk, spell)

  let withdraw_redeemer: Redeemer = { input_arg }

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [
      Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
      Pair(Spend(mock_outref), spell_redeemer),
    ]

  expect redeemer: ByteArray = spell_redeemer
  let datum = Some(spell_datum)

  let app_vk = #"deadbeef"

  main.spend(
    test_beacon_parts.policy_id,
    app_vk,
    datum,
    redeemer,
    mock_outref,
    Transaction { ..placeholder, redeemers, outputs: [mock_output] },
  )
}

// test main_spend_vk_0_inputs() fail {
//   // downcast public values
//   let public_values: Data = base_passing_circuit().public_values
//   let app =
//     App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
//   let app_public_inputs = [Pair(app, public_values)]

//   // Create a mock spell and spell datum
//   let spell: NormalizedSpell =
//     NormalizedSpell {
//       version: 1,
//       tx: placeholder,
//       app_public_inputs,
//       mock: True,
//     }

//   // Create mock spell redeemer
//   let spell_redeemer: Redeemer = "1"

//   // Create mock transaction with required outputs
//   let mock_output =
//     Output {
//       address: Address {
//         payment_credential: Script(base_passing_circuit().sh),
//         stake_credential: None,
//       },
//       value: from_asset(#"", #"", 100),
//       datum: NoDatum,
//       reference_script: None,
//     }

//   let mock_outref = OutputReference { transaction_id: #"", output_index: 0 }

//   let expected_public_values: List<Int> =
//     cbor_serialize(base_passing_circuit().vk, spell)

//   let withdraw_redeemer: Redeemer =
//     WithdrawRedeemer { input_arg: base_passing_circuit().vk }

//   let redeemers: Pairs<ScriptPurpose, Redeemer> =
//     [
//       Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
//       Pair(Spend(mock_outref), spell_redeemer),
//     ]

//   expect redeemer: ByteArray = spell_redeemer
//   let spell_datum: Data = NoDatum
//   let datum = Some(spell_datum)

//   let app_vk = #"deadbeef"

//   main.spend(
//     test_beacon_parts.policy_id,
//     app_vk,
//     datum,
//     redeemer,
//     mock_outref,
//     Transaction { ..placeholder, redeemers, outputs: [mock_output] },
//   )
// }

// test main_mint_pass() {
//   // downcast public values
//   let public_values: Data = base_passing_circuit().public_values
//   let app =
//     App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
//   let app_public_inputs = [Pair(app, public_values)]

//   // Create a mock spell and spell datum
//   let spell: NormalizedSpell =
//     NormalizedSpell {
//       version: 1,
//       tx: placeholder,
//       app_public_inputs,
//       mock: True,
//     }

//   // Add other required fields based on your NormalizedSpell definition
//   let spell_datum: SpellDatum =
//     SpellDatum { spell, proof: base_passing_circuit().proof }

//   // Create mock spell redeemer
//   let spell_redeemer: Redeemer = "1"

//   // Create mock transaction with required outputs
//   let mock_output =
//     Output {
//       address: Address {
//         payment_credential: Script(base_passing_circuit().sh),
//         stake_credential: None,
//       },
//       value: from_asset(#"", #"", 100),
//       datum: InlineDatum(spell_datum),
//       reference_script: None,
//     }

//   let policy_id: PolicyId =
//     #"abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"

//   let expected_public_values: List<Int> =
//     cbor_serialize(base_passing_circuit().vk, spell)

//   let withdraw_redeemer: Redeemer =
//     WithdrawRedeemer { input_arg: base_passing_circuit().vk }

//   let redeemers: Pairs<ScriptPurpose, Redeemer> =
//     [
//       Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
//       Pair(Mint(policy_id), spell_redeemer),
//     ]

//   expect redeemer: ByteArray = spell_redeemer

//   let app_vk = #"deadbeef"

//   main.mint(
//     test_beacon_parts.policy_id,
//     app_vk,
//     redeemer,
//     policy_id,
//     Transaction { ..placeholder, redeemers, outputs: [mock_output] },
//   )
// }

// test main_mint_fail_no_output() fail {
//   // downcast public values
//   let public_values: Data = base_passing_circuit().public_values
//   let app =
//     App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
//   let app_public_inputs = [Pair(app, public_values)]

//   // Create a mock spell and spell datum
//   let spell: NormalizedSpell =
//     NormalizedSpell {
//       version: 1,
//       tx: placeholder,
//       app_public_inputs,
//       mock: True,
//     }

//   // Create mock spell redeemer
//   let spell_redeemer: Redeemer = "1"

//   let policy_id: PolicyId =
//     #"abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"

//   let expected_public_values: List<Int> =
//     cbor_serialize(base_passing_circuit().vk, spell)

//   let withdraw_redeemer: Redeemer =
//     WithdrawRedeemer { input_arg: base_passing_circuit().vk }

//   let redeemers: Pairs<ScriptPurpose, Redeemer> =
//     [
//       Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
//       Pair(Mint(policy_id), spell_redeemer),
//     ]

//   expect redeemer: ByteArray = spell_redeemer

//   let app_vk = #"deadbeef"

//   // No outputs - this should cause the mint to fail when trying to get the last output
//   main.mint(
//     test_beacon_parts.policy_id,
//     app_vk,
//     redeemer,
//     policy_id,
//     Transaction { ..placeholder, redeemers, outputs: [] },
//   )
// }
