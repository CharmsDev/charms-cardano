use aiken/collection/list
use aiken/primitive/int.{from_utf8}
use ak_381/groth16.{Proof, SnarkVerificationKey, groth_verify}
use cardano/address.{Address, Credential, Script}
use cardano/assets.{from_asset}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{InlineDatum, Output, Transaction, placeholder}
use charms_cardano/charms.{
  NormalizedSpell, SpellDatum, cbor_serialize, extract_spell,
}
use charms_cardano/test_utils.{base_passing_circuit, mock_normalized_spell}

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
  let redeemer = "7"
  expect Some(version) = from_utf8(redeemer)
  let spell = mock_normalized_spell()
  let spell_datum: SpellDatum =
    SpellDatum { spell, proof: base_passing_circuit().proof }

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

// Direct unit test: verifies the ak-381 groth_verify function works with the
// 3-factorial fixtures from base_passing_circuit(), bypassing cbor_serialize.
// This is separate from the full validator-level test (see groth_verify_pass below).
test groth_verify_direct_pass() {
  groth_verify(
    base_passing_circuit().vk,
    base_passing_circuit().proof,
    base_passing_circuit().public_values,
  )
}

// Uses the valid VK but with piA and piC swapped — all points are on-curve so
// blst won't error, but the pairing check fails because the proof is invalid.
test groth_verify_direct_fail() fail {
  let bad_proof =
    Proof {
      piA: base_passing_circuit().proof.piC,
      piB: base_passing_circuit().proof.piB,
      piC: base_passing_circuit().proof.piA,
    }

  groth_verify(
    base_passing_circuit().vk,
    bad_proof,
    base_passing_circuit().public_values,
  )
}
