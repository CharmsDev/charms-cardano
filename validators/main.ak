use aiken/builtin.{verify_schnorr_secp256k1_signature}
use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{ScriptHash}
use cardano/address.{Address, Credential, Script}
use cardano/assets.{PolicyId, from_asset, has_nft}
use cardano/certificate.{Certificate}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{
  InlineDatum, NoDatum, Output, OutputReference, Redeemer, ScriptPurpose, Spend,
  Transaction, Withdraw, placeholder,
}
use charms_cardano/beacon.{BeaconParts}
use charms_cardano/charms.{App, NormalizedSpell, cbor_serialize}
use charms_cardano/test_utils.{
  TestCircuit, base_passing_circuit, test_beacon_parts,
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

  publish(_redeemer: ByteArray, _certificate: Certificate, _self: Transaction) {
    // Allow registration/deregistration without signature verification
    True
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

  let withdraw_redeemer: Redeemer = input_arg

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

test scrolls_verify_schnorr_signature() {
  // // BIP-340 test vector #0
  // // Private key: 0000000000000000000000000000000000000000000000000000000000000003
  // // Public key (x-only): F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9
  // // Message: 0000000000000000000000000000000000000000000000000000000000000000
  // // Signature: E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0
  // let vkey = #"f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9"
  // let txid = #"0000000000000000000000000000000000000000000000000000000000000000"
  // let signature =
  //   #"e907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca821525f66a4a85ea8b71e482a74f382d2ce5ebeee8fdb2172f477df4900d310536c0"

  // Scrolls
  let vkey = #"aa75665a675fc5bcbaded7b8ae8d833b07d3559ab352db6c83efd361392840cb"
  let txid = #"d21afcf98117329cb8ad034c9e1f712684cbec800b8129241f827ac9bc9f4027"
  let signature =
    #"2ce5f83a9a6691e952de9590b87c2389af6dad2c8880808a8d91468c9de94de50953e71c624c78cdbd7196291b33115d5df02ec87da191cce198af06cbc3f044"

  verify_schnorr_secp256k1_signature(vkey, txid, signature)
}
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
