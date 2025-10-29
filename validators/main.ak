use aiken/builtin.{serialise_data}
use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken_design_patterns/merkelized_validator.{WithdrawRedeemer}
use ak_381/groth16.{SnarkVerificationKey}
use cardano/address.{Address, Script}
use cardano/assets.{PolicyId, from_asset}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{
  Datum, DatumHash, InlineDatum, NoDatum, Output, OutputReference, Redeemer,
  ScriptPurpose, Spend, Transaction, Withdraw, placeholder,
}
use charms_cardano/charms.{App, NormalizedSpell, SpellDatum, SpellRedeemer}
use charms_cardano/groth.{Groth16Inputs, groth16_input_coercer}
use charms_cardano/test_utils.{TestCircuit, base_passing_circuit}
use charms_cardano/utils.{bytearray_to_list}

validator main(merkelized_groth16: ScriptHash, groth_vk: SnarkVerificationKey) {
  mint(redeemer: SpellRedeemer, _policy_id: PolicyId, self: Transaction) {
    //TODO: Confirm the token name is correct

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
    datum_opt: Option<SpellDatum>,
    redeemer: SpellRedeemer,
    _utxo: OutputReference,
    self: Transaction,
  ) {
    expect Some(SpellDatum { spell, proof }) = datum_opt

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

test main_spend_pass() {
  // downcast public values
  let public_values: Data = base_passing_circuit().public_values
  let app =
    App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
  let app_public_inputs = [Pair(app, public_values)]

  // Create a mock spell and spell datum
  let spell: NormalizedSpell =
    NormalizedSpell {
      version: 1,
      tx: placeholder,
      app_public_inputs,
      mock: True,
    }

  // Add other required fields based on your NormalizedSpell definition
  let spell_datum: SpellDatum =
    SpellDatum { spell, proof: base_passing_circuit().proof }

  // Create mock spell redeemer
  let spell_redeemer: Redeemer =
    SpellRedeemer { spell_vk: base_passing_circuit().vk }

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
    to_serialized_pv(spell, base_passing_circuit().vk)

  let withdraw_redeemer: Redeemer =
    WithdrawRedeemer {
      input_arg: Groth16Inputs {
        vk: base_passing_circuit().vk,
        proof: base_passing_circuit().proof,
        public_values: expected_public_values,
      },
    }

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [
      Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
      Pair(Spend(mock_outref), spell_redeemer),
    ]

  expect redeemer: SpellRedeemer = spell_redeemer
  let datum = Some(spell_datum)

  main.spend(
    base_passing_circuit().sh,
    base_passing_circuit().vk,
    datum,
    redeemer,
    mock_outref,
    Transaction { ..placeholder, redeemers, outputs: [mock_output] },
  )
}

test main_spend_vk_0_inputs() fail {
  // downcast public values
  let public_values: Data = base_passing_circuit().public_values
  let app =
    App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
  let app_public_inputs = [Pair(app, public_values)]

  // Create a mock spell and spell datum
  let spell: NormalizedSpell =
    NormalizedSpell {
      version: 1,
      tx: placeholder,
      app_public_inputs,
      mock: True,
    }

  // Add other required fields based on your NormalizedSpell definition
  let spell_datum: SpellDatum =
    SpellDatum { spell, proof: base_passing_circuit().proof }

  // Create mock spell redeemer
  let spell_redeemer: Redeemer =
    SpellRedeemer {
      spell_vk: SnarkVerificationKey { ..base_passing_circuit().vk, nPublic: 0 },
    }

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
    to_serialized_pv(spell, base_passing_circuit().vk)

  let withdraw_redeemer: Redeemer =
    WithdrawRedeemer {
      input_arg: Groth16Inputs {
        vk: base_passing_circuit().vk,
        proof: base_passing_circuit().proof,
        public_values: expected_public_values,
      },
    }

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [
      Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
      Pair(Spend(mock_outref), spell_redeemer),
    ]

  expect redeemer: SpellRedeemer = spell_redeemer
  let datum = Some(spell_datum)

  main.spend(
    base_passing_circuit().sh,
    base_passing_circuit().vk,
    datum,
    redeemer,
    mock_outref,
    Transaction { ..placeholder, redeemers, outputs: [mock_output] },
  )
}
