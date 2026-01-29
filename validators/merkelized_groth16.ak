use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken_design_patterns/merkelized_validator.{WithdrawRedeemerIO}
// use ak_381/groth16.{Proof}
use ak_381/groth16.{SnarkVerificationKey, groth_verify}
use cardano/address.{Credential, Script}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction, placeholder}
use charms_cardano/charms.{SpellDatum, cbor_serialize, extract_spell}

// use charms_cardano/test_utils.{base_passing_circuit}

validator merkelized_groth16(
  groth_vk: SnarkVerificationKey,
  charms_version: Int,
) {
  withdraw(
    redeemer: WithdrawRedeemerIO<Data, Bool>,
    _account: Credential,
    self: Transaction,
  ) {
    merkelized_validator.withdraw_io(
      fn(inputs: Data) -> Bool {
        // extract spell_vk from redeemer
        expect spell_vk: SnarkVerificationKey = inputs

        // find spell output
        expect Some(spell_output) = list.last(self.outputs)

        // extract spell datum
        expect SpellDatum { spell, proof } = extract_spell(spell_output.datum)

        // verify charms version
        expect spell.version == charms_version

        // serialize public inputs
        let app_public_inputs = cbor_serialize(spell_vk, spell)

        // verify groth16 proof
        groth_verify(groth_vk, proof, app_public_inputs)
      },
      redeemer,
    )
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in merkelized_groth16"
  }
}

// test groth_verify_pass() {
//   let input_arg: Data = base_passing_circuit().vk
//   let redeemer: WithdrawRedeemerIO<Data, Bool> =
//     WithdrawRedeemerIO { input_arg, result: True }

//   merkelized_groth16.withdraw(
//     base_passing_circuit().vk,
//     1,
//     redeemer,
//     Script(base_passing_circuit().sh),
//     placeholder,
//   )
// }

test groth_verify_fail() fail {
  let m16_sh: ScriptHash =
    #"f5f1a4c8b3e6e2c3d4b5a69788796a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e0f"

  //  Template of VK
  let vk: SnarkVerificationKey =
    SnarkVerificationKey {
      nPublic: 2,
      vkAlpha: #"8e3d9e248feda194cb6fa0a3b64fd2a380cb5e94836bf7148bf97ebcbb5819d9a78f63102f0293c104bcbb2f810d8eb4",
      vkBeta: #"8cd68a7186a908212680a0234d8210c20328f8fb3ce1d69c9aec9330a5802d6cfaf6d7cf3176133221c19188590cb4141874ea7bbfcb9872931e115d882c46b90c3dcbcee10062d1c9b9b0a691d7bec7d2735f06495c7f71dea210e55b2782df",
      vkGamma: #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
      vkDelta: #"938231fcec443fbdeb1079ff126b8f69bd8579ffe82d39923214d4345395beee60200288fa20c97ae50f3212131b6f8802af2f9f515c65af6a9a6c294c738590104376a0af44731d6699db6a286608774243f7d1dddc4605eb340e65e15060a5",
      vkAlphaBeta: [
        #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
      ],
      vkIC: [
        #"b5813c90d3455acb8608fdf66e8601f24ef048f3fdf9384862d77c72cb5cddfde2b307976b1b0319c42ba985f94be60a",
        #"a41a0e6370c054be0f9acce08e97f6d5702d9daa9e9a934e8a377f553593baa1c58062adc73d63558653422d54d6f50c",
        #"8e02a87c519c3145f984d25fdf769f74fbc36626c385d4554fb4bc1d7a12cbf669d40f257023b8b3c9a31e631aa8f981",
      ],
    }

  let data_vk: Data = vk

  // //  Template of Proof
  // let pk: Proof =
  //   Proof {
  //     piA: #"8b84d092731c653b1accdda79c51e3f5d289bed7311189d927deadef0470e437e6d1d400634726512a79a015867424e3",
  //     piB: #"92cb1c125816e4b522c7f430a5d74a61116b6189de7b2341f040194c02f10d9ef0cf081f4029444a65ea74e69d98b1cf08d3864087d5d2dee2ed6ab102f9b78e65d341f0824341a9fc25d0ea9dacccc5d355b4eddb0057949370a19c47135b0e",
  //     piC: #"a4ef633c858a3ff194db50eacdf715f7296fb3d1202c54b543284e9656b69aa90f33ac0e2572d3ab847b88268dcd1f7e",
  //   }
  // Template of public values
  // let public_values: List<Int> = [561, 3]
  let redeemer: WithdrawRedeemerIO<Data, Bool> =
    WithdrawRedeemerIO { input_arg: data_vk, result: True }

  merkelized_groth16.withdraw(vk, 1, redeemer, Script(m16_sh), placeholder)
}
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
