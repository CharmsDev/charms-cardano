use aiken/collection/list
use aiken_design_patterns/merkelized_validator.{WithdrawRedeemer}
use ak_381/groth16.{SnarkVerificationKey}
use cardano/address.{Address, Script}
use cardano/assets.{PolicyId, from_asset}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{
  InlineDatum, Mint,  Output, OutputReference,
  Redeemer, ScriptPurpose, Spend, Transaction, Withdraw, placeholder,
}
use charms_cardano/charms.{App, NormalizedSpell, SpellDatum, SpellRedeemer, cbor_serialize}
use charms_cardano/test_utils.{TestCircuit, base_passing_circuit, test_beacon_parts}
use charms_cardano/utils.{has_beacon}
use charms_cardano/beacon.{BeaconParts}

validator main(beacon_parts: BeaconParts) {
  mint(redeemer: SpellRedeemer, _policy_id: PolicyId, self: Transaction) {
    expect Some(beacon_ref_input) = list.last(self.reference_inputs)

    expect Some(charms_validator) = beacon_ref_input.output.reference_script

    has_beacon(beacon_parts, redeemer.charms_version, beacon_ref_input.output.value) && 
    merkelized_validator.delegated_validation(
      function_input: redeemer.input_args,
      staking_validator: charms_validator,
      input_data_coercer: fn(d: Data) { d }, // expect generic data - coercion is specified within the validator
      redeemers: self.redeemers,
    )
  }

  /// Confirm the Merkelized Validator has signed the Tx
  /// [Optional] Confirm outputs conform to the Charm Assetname Standard
  spend(
    _datum_opt: Option<SpellDatum>,
    redeemer: SpellRedeemer,
    _utxo: OutputReference,
    self: Transaction,
  ) {
    expect Some(beacon_ref_input) = list.last(self.reference_inputs)
    expect has_beacon(beacon_parts, redeemer.charms_version, beacon_ref_input.output.value)

    expect Some(charms_validator) = beacon_ref_input.output.reference_script

    merkelized_validator.delegated_validation(
      function_input: redeemer.input_args,
      staking_validator: charms_validator,
      input_data_coercer: fn(d: Data) { d }, // expect generic data - coercion is specified within the validator
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

test main_spend_pass() {
  // downcast public values
  let public_values: Data = base_passing_circuit().public_values
  let app =
    App { tag: @"test_app", identity: #"abcdef", vk: base_passing_circuit().vk }
  let app_public_inputs = [Pair(app, public_values)]
  let placeholder_data: Data = placeholder
  let input_args = base_passing_circuit().vk

  // Create a mock spell and spell datum
  let spell: NormalizedSpell =
    NormalizedSpell {
      version: 1,
      tx: placeholder_data,
      app_public_inputs,
      mock: True,
    }

  // Add other required fields based on your NormalizedSpell definition
  let spell_datum: SpellDatum =
    SpellDatum { spell, proof: base_passing_circuit().proof }

  // Create mock spell redeemer
  let spell_redeemer: Redeemer =
    SpellRedeemer { input_args, charms_version: 1 }

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

  let withdraw_redeemer: Redeemer =
    WithdrawRedeemer {
      input_arg: input_args
    }

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [
      Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
      Pair(Spend(mock_outref), spell_redeemer),
    ]

  expect redeemer: SpellRedeemer = spell_redeemer
  let datum = Some(spell_datum)

  main.spend(
    test_beacon_parts,
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
      input_args: SnarkVerificationKey { ..base_passing_circuit().vk, nPublic: 0 },
      charms_version: 1
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
    cbor_serialize(base_passing_circuit().vk, spell)

  let withdraw_redeemer: Redeemer =
    WithdrawRedeemer {
      input_arg: base_passing_circuit().vk
    }

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [
      Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
      Pair(Spend(mock_outref), spell_redeemer),
    ]

  expect redeemer: SpellRedeemer = spell_redeemer
  let datum = Some(spell_datum)

  main.spend(
    test_beacon_parts,
    datum,
    redeemer,
    mock_outref,
    Transaction { ..placeholder, redeemers, outputs: [mock_output] },
  )
}

test main_mint_pass() {
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
    SpellRedeemer { input_args: base_passing_circuit().vk, charms_version: 1 }

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

  let policy_id: PolicyId =
    #"abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"

  let expected_public_values: List<Int> =
    cbor_serialize(base_passing_circuit().vk, spell)

  let withdraw_redeemer: Redeemer =
    WithdrawRedeemer {
      input_arg: base_passing_circuit().vk
    }

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [
      Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
      Pair(Mint(policy_id), spell_redeemer),
    ]

  expect redeemer: SpellRedeemer = spell_redeemer

  main.mint(
    test_beacon_parts,
    redeemer,
    policy_id,
    Transaction { ..placeholder, redeemers, outputs: [mock_output] },
  )
}

test main_mint_fail_no_output() fail {
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

  // Create mock spell redeemer
  let spell_redeemer: Redeemer =
    SpellRedeemer { input_args: base_passing_circuit().vk, charms_version: 1 }

  let policy_id: PolicyId =
    #"abcdef1234567890abcdef1234567890abcdef1234567890abcdef12"

  let expected_public_values: List<Int> =
    cbor_serialize(base_passing_circuit().vk, spell)

  let withdraw_redeemer: Redeemer =
    WithdrawRedeemer {
      input_arg: base_passing_circuit().vk
    }

  let redeemers: Pairs<ScriptPurpose, Redeemer> =
    [
      Pair(Withdraw(Script(base_passing_circuit().sh)), withdraw_redeemer),
      Pair(Mint(policy_id), spell_redeemer),
    ]

  expect redeemer: SpellRedeemer = spell_redeemer

  // No outputs - this should cause the mint to fail when trying to get the last output
  main.mint(
    test_beacon_parts,
    redeemer,
    policy_id,
    Transaction { ..placeholder, redeemers, outputs: [] },
  )
}
