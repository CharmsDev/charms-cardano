use cardano/transaction.{Datum, DatumHash, InlineDatum, NoDatum, Transaction, OutputReference}
use cardano/script_context.{ScriptContext}
use aiken_design_patterns/merkelized_validator
use aiken/crypto.{ScriptHash}
use charms_cardano/types.{Groth16Inputs, groth16_input_coercer}
use cardano/assets.{PolicyId}
use ak_381/groth16.{SnarkVerificationKey}
use aiken/collection/list
use charms_cardano/charms.{NormalizedSpell, SpellDatum, SpellRedeemer}
use aiken/builtin.{
  serialise_data
}
use charms_cardano/utils.{bytearray_to_list}


validator main(
  merkelized_groth16: ScriptHash,
  groth_vk: SnarkVerificationKey
) {
  mint(_redeemer: Data, _policy_id: PolicyId, _self: Transaction) {

    /// Confirm the Merkelized Validator has signed the Tx
    /// [Optional] Confirm outputs conform to the Charm Assetname Standard
    todo @"mint logic goes here"
  }

  spend(_datum_opt: Option<Data>, redeemer: SpellRedeemer, utxo: OutputReference, self: Transaction) {
    /// Identify Charms - Check for utxos which contain a charms datum / charms native asset
    // expect Some(spell_input) = find_input(self.inputs, utxo) // left out for testing purposes
    expect Some(spell_output) = list.last(self.outputs)
    
    /// Confirm the spell datum has not been changed
    // expect spell_input.output.datum == spell_output.datum // left out for testing purposes

    /// Parse Charms data - Retrieve the following parameters from said utxos:
    /// a. Groth Verification Key | parameter/redeemer
    /// - groth_vk is passed as a parameter to the validator

    /// b. Proof | in a tuple of (spell, proof) in the change output
    expect SpellDatum {spell, proof} = extract_spell(spell_output.datum)

    /// c. Public Inputs (App Data, App VK) | parse from spell, inputs
    let app_public_inputs = to_serialized_pv(spell, redeemer.spell_vk)

    let groth_inputs: Groth16Inputs = Groth16Inputs {
      vk: groth_vk,
      proof: proof,
      public_values: app_public_inputs
    }

    /// Confirm the params listed in the redeemer match those acquired in step 2
    // TODO

    /// Confirm the Merkelized Validator has signed the Tx
    merkelized_validator.delegated_validation(
      function_input: groth_inputs,
      staking_validator: merkelized_groth16,
      input_data_coercer: groth16_input_coercer,
      redeemers: self.redeemers
    )

      /// Confirm nothing else has been spent from this address
      // TODO
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in main"
  }
}

fn extract_spell(datum: Datum) -> Data {
    when datum is {
    NoDatum -> fail
    DatumHash(h) -> {
      fail // just fail with DatumHash for now
      // expect Some(d) = dict.get(tx_datums, h)
      // d
    }
    InlineDatum(d) -> d
  }
}

// fn to_serialized_pv2(spell_version: Int, data: SpellData) -> ByteArray {
//     // For all supported versions except V0, use CBOR encoding of the tuple
//     if spell_version == 0 {
//         // For V0, you may need to match the legacy serialization format.
//         // This is a placeholder; you must implement the legacy logic if needed.
//         // For now, just CBOR encode as well.
//         builtin.serialize_data((data.spell_vk, data.n_spell))
//     } else {
//         // Standard CBOR encoding for (spell_vk, n_spell)
//         builtin.serialize_data((data.spell_vk, data.n_spell))
//     }
// }

fn to_serialized_pv(spell: NormalizedSpell, spell_vk: SnarkVerificationKey) -> List<Int> {
  when spell.version is {
    0 -> {
      // Legacy: commit to tuple (spell_vk, spell) using old serialization
      sp1_serialize((spell_vk, spell))
    }
    _ -> {
      // Commit to CBOR-encoded tuple (spell_vk, spell)
      let cbor_vec: List<Int> = cbor_serialize((spell_vk, spell))
      cbor_vec
    }
  }
}

fn sp1_serialize(data: (SnarkVerificationKey, NormalizedSpell)) -> List<Int> {
  // Probably doesn't make sense to support SP1 serialization? Will revisit.

  expect sp1: List<Int> = bytearray_to_list(serialise_data(data))
  sp1
}

fn cbor_serialize(data: (SnarkVerificationKey, NormalizedSpell)) -> List<Int> {
  bytearray_to_list(serialise_data(data))
}

//   //  Template of VK
//   let vk: SnarkVerificationKey =
//     SnarkVerificationKey {
//       nPublic: 2,
//       vkAlpha: #"8e3d9e248feda194cb6fa0a3b64fd2a380cb5e94836bf8148bf97ebcbb5819d9a78f63102f0293c104bcbb2f810d8eb4",
//       vkBeta: #"8cd68a7186a908212680a0234d8210c20328f8fb3ce1d69c9aec9330a5802d6cfaf6d7cf3176133221c19188590cb4141874ea7bbfcb9872931e115d882c46b90c3dcbcee10062d1c9b9b0a691d7bec7d2735f06495c7f71dea210e55b2782df",
//       vkGamma: #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
//       vkDelta: #"938231fcec443fbdeb1079ff126b8f69bd8579ffe82d39923214d4345395beee60200288fa20c97ae50f3212131b6f8802af2f9f515c65af6a9a6c294c738590104376a0af44731d6699db6a286608774243f7d1dddc4605eb340e65e15060a5",
//       vkAlphaBeta: [
//         #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
//       ],
//       vkIC: [
//         #"b5813c90d3455acb8608fdf66e8601f24ef048f3fdf9384862d77c72cb5cddfde2b307976b1b0319c42ba985f94be60a",
//         #"a41a0e6370c054be0f9acce08e97f6d5702d9daa9e9a934e8a377f553593baa1c58062adc73d63558653422d54d6f50c",
//         #"8e02a87c519c3145f984d25fdf769f74fbc36626c385d4554fb4bc1d7a12cbf669d40f257023b8b3c9a31e631aa8f981",
//       ],
//     }

//   //  Template of Proof
//   let pk: Proof =
//     Proof {
//       piA: #"8b84d092731c653b1accdda79c51e3f5d289bed7311189d927deadef0470e437e6d1d400634726512a79a015867424e3",
//       piB: #"92cb1c125816e4b522c7f430a5d74a61116b6189de7b2341f040194c02f10d9ef0cf081f4029444a65ea74e69d98b1cf08d3864087d5d2dee2ed6ab102f9b78e65d341f0824341a9fc25d0ea9dacccc5d355b4eddb0057949370a19c47135b0e",
//       piC: #"a4ef633c858a3ff194db50eacdf715f7296fb3d1202c54b543284e9656b69aa90f33ac0e2572d3ab847b88268dcd1f7e",
//     }
//   // Template of public values
//   let public_values: List<Int> =
//     [561, 3]

//   merkelized_validator.delegated_validation(
//     function_input: Groth16Inputs(vk, pk, public_values),
//     staking_validator: merkelized_groth16,
//     input_data_coercer: groth16_input_coercer,
//     redeemers: [Pair(ScriptPurpose("Spend"), Groth16Inputs(vk, pk, public_values))]
//   )
// }

// test groth_verify_fail_1() fail {
//   //  Template of VK
//   let vk: SnarkVerificationKey =
//     SnarkVerificationKey {
//       nPublic: 2,
//       vkAlpha: #"8e3d9e248feda194cb6fa0a3b64fd2a380cb5e94836bf8148bf97ebcbb5819d9a78f63102f0293c104bcbb2f810d8eb4",
//       vkBeta: #"8cd68a7186a908212680a0234d8210c20328f8fb3ce1d69c9aec9330a5802d6cfaf6d7cf3176133221c19188590cb4141874ea7bbfcb9872931e115d882c46b90c3dcbcee10062d1c9b9b0a691d7bec7d2735f06495c7f71dea210e55b2782df",
//       vkGamma: #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
//       vkDelta: #"938231fcec443fbdeb1079ff126b8f69bd8579ffe82d39923214d4345395beee60200288fa20c97ae50f3212131b6f8802af2f9f515c65af6a9a6c294c738590104376a0af44731d6699db6a286608774243f7d1dddc4605eb340e65e15060a5",
//       vkAlphaBeta: [
//         #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
//       ],
//       vkIC: [
//         #"b5813c90d3455acb8608fdf66e8601f24ef048f3fdf9384862d77c72cb5cddfde2b307976b1b0319c42ba985f94be60a",
//         #"a41a0e6370c054be0f9acce08e97f6d5702d9daa9e9a934e8a377f553593baa1c58062adc73d63558653422d54d6f50c",
//         #"8e02a87c519c3145f984d25fdf769f74fbc36626c385d4554fb4bc1d7a12cbf669d40f257023b8b3c9a31e631aa8f981",
//       ],
//     }

//   //  Template of Proof
//   let pk: Proof =
//     Proof {
//       piA: #"a4ef633c858a3ff194db50eacdf715f7296fb3d1202c54b543284e9656b69aa90f33ac0e2572d3ab847b88268dcd1f7e",
//       piB: #"92cb1c125816e4b522c7f430a5d74a61116b6189de7b2341f040194c02f10d9ef0cf081f4029444a65ea74e69d98b1cf08d3864087d5d2dee2ed6ab102f9b78e65d341f0824341a9fc25d0ea9dacccc5d355b4eddb0057949370a19c47135b0e",
//       piC: #"8b84d092731c653b1accdda79c51e3f5d289bed7311189d927deadef0470e437e6d1d400634726512a79a015867424e3",
//     }
//   // Template of public values
//   let public_values: List<Int> =
//     [561, 3]

//   groth_verify(vk, pk, public_values)
// }