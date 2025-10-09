use aiken/builtin.{serialise_data}
use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken_design_patterns/merkelized_validator
use ak_381/groth16.{SnarkVerificationKey}
use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{
  Datum, DatumHash, InlineDatum, NoDatum, OutputReference,
  Transaction
}
use charms_cardano/charms.{NormalizedSpell, SpellDatum, SpellRedeemer}
use charms_cardano/types.{Groth16Inputs, groth16_input_coercer}
use charms_cardano/utils.{bytearray_to_list}

validator main(merkelized_groth16: ScriptHash, groth_vk: SnarkVerificationKey) {
  mint(redeemer: SpellRedeemer, _policy_id: PolicyId, self: Transaction) {
        // expect Some(spell_input) = find_input(self.inputs, utxo) // left out for testing purposes
    expect Some(spell_output) = list.last(self.outputs)

    // expect spell_input.output.datum == spell_output.datum // left out for testing purposes
    expect SpellDatum { spell, proof } = extract_spell(spell_output.datum)

    let app_public_inputs = to_serialized_pv(spell, redeemer.spell_vk)

    let groth_inputs: Groth16Inputs =
      Groth16Inputs { vk: groth_vk, proof, public_values: app_public_inputs }

    merkelized_validator.delegated_validation(
      function_input: groth_inputs,
      staking_validator: merkelized_groth16,
      input_data_coercer: groth16_input_coercer,
      redeemers: self.redeemers,
    )
  }

  /// Confirm the Merkelized Validator has signed the Tx
  /// [Optional] Confirm outputs conform to the Charm Assetname Standard
  spend(
    _datum_opt: Option<Data>,
    redeemer: SpellRedeemer,
    _utxo: OutputReference,
    self: Transaction,
  ) {
    // expect Some(spell_input) = find_input(self.inputs, utxo) // left out for testing purposes
    expect Some(spell_output) = list.last(self.outputs)

    // expect spell_input.output.datum == spell_output.datum // left out for testing purposes
    expect SpellDatum { spell, proof } = extract_spell(spell_output.datum)

    let app_public_inputs = to_serialized_pv(spell, redeemer.spell_vk)

    let groth_inputs: Groth16Inputs =
      Groth16Inputs { vk: groth_vk, proof, public_values: app_public_inputs }

    merkelized_validator.delegated_validation(
      function_input: groth_inputs,
      staking_validator: merkelized_groth16,
      input_data_coercer: groth16_input_coercer,
      redeemers: self.redeemers,
    )
  }

  /// Identify Charms - Check for utxos which contain a charms datum / charms native asset
  /// Confirm the spell datum has not been changed
  /// Parse Charms data - Retrieve the following parameters from said utxos:
  /// a. Groth Verification Key | parameter/redeemer
  /// - groth_vk is passed as a parameter to the validator
  /// b. Proof | in a tuple of (spell, proof) in the change output
  /// c. Public Inputs (App Data, App VK) | parse from spell, inputs
  /// Confirm the params listed in the redeemer match those acquired in step 2
  /// Confirm the Merkelized Validator has signed the Tx
  /// Confirm nothing else has been spent from this address
  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in main"
  }
}

fn extract_spell(datum: Datum) -> Data {
  when datum is {
    NoDatum -> fail
    DatumHash(_h) -> fail
    // just fail with DatumHash for now
    // expect Some(d) = dict.get(tx_datums, h)
    // d
    InlineDatum(d) -> d
  }
}

fn to_serialized_pv(
  spell: NormalizedSpell,
  spell_vk: SnarkVerificationKey,
) -> List<Int> {
  when spell.version is {
    0 ->
      // Legacy: commit to tuple (spell_vk, spell) using old serialization
      sp1_serialize((spell_vk, spell))
    _ ->
      // Commit to CBOR-encoded tuple (spell_vk, spell)
      cbor_serialize((spell_vk, spell))
  }
}

fn sp1_serialize(data: (SnarkVerificationKey, NormalizedSpell)) -> List<Int> {
  // Probably doesn't make sense to support SP1 serialization? Will revisit.

  bytearray_to_list(serialise_data(data))

}

fn cbor_serialize(data: (SnarkVerificationKey, NormalizedSpell)) -> List<Int> {
  bytearray_to_list(serialise_data(data))
}