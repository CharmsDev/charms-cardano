use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken/primitive/int.{from_utf8}
use ak_381/groth16.{SnarkVerificationKey, groth_verify}
use cardano/address.{Address, Credential, Script}
use cardano/assets.{from_asset}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{InlineDatum, Output, Transaction, placeholder}
use charms_cardano/charms.{
  App, NormalizedSpell, SpellDatum, cbor_serialize, extract_spell,
}
use charms_cardano/test_utils.{base_passing_circuit}

validator staking_groth16(spell_vk: SnarkVerificationKey, charms_version: Int) {
  withdraw(_redeemer: ByteArray, _account: Credential, self: Transaction) {
    // find spell output
    expect Some(spell_output) = list.last(self.outputs)

    // extract spell datum
    expect SpellDatum { spell, proof } = extract_spell(spell_output.datum)

    // verify charms version
    //expect Some(version) = from_utf8(redeemer) // not needed?
    expect charms_version == spell.version

    // serialize public inputs
    let app_public_inputs = cbor_serialize(spell_vk, spell)

    // verify groth16 proof
    groth_verify(spell_vk, proof, app_public_inputs)
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in staking_groth16"
  }
}

test groth_verify_pass() {
  let redeemer = "1"
  expect Some(version) = from_utf8(redeemer)
  let public_values: Data = base_passing_circuit().public_values
  let app =
    App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
  let app_public_inputs = [Pair(app, public_values)]
  let spell: NormalizedSpell =
    NormalizedSpell {
      version: 1,
      tx: placeholder,
      app_public_inputs,
      mock: True,
    }
  let spell_datum: SpellDatum =
    SpellDatum { spell, proof: base_passing_circuit().proof }

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

  let tx = Transaction { ..placeholder, outputs: [mock_output] }

  staking_groth16.withdraw(
    base_passing_circuit().vk,
    version,
    redeemer,
    Script(base_passing_circuit().sh),
    tx,
  )
}

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

  let redeemer = "1"
  expect Some(version) = from_utf8(redeemer)
  let public_values: Data = base_passing_circuit().public_values
  let app =
    App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
  let app_public_inputs = [Pair(app, public_values)]
  let spell: NormalizedSpell =
    NormalizedSpell {
      version: 1,
      tx: placeholder,
      app_public_inputs,
      mock: True,
    }
  let spell_datum: SpellDatum =
    SpellDatum { spell, proof: base_passing_circuit().proof }

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

  let tx = Transaction { ..placeholder, outputs: [mock_output] }

  staking_groth16.withdraw(vk, version, redeemer, Script(m16_sh), tx)
}
