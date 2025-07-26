use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}
use ak_381/groth16.{SnarkVerificationKey, Proof, groth_verify}
use aiken_design_patterns/merkelized_validator.{WithdrawRedeemerIO}
use cardano/address.{Credential}
use charms_cardano/types.{Groth16Inputs}

validator merkelized_groth16 {
  withdraw(redeemer: WithdrawRedeemerIO<Groth16Inputs, Bool>, _account: Credential, _self: Transaction) {
    /// Extract parameters from the redeemer & run groth 16 validation
    merkelized_validator.withdraw_io(
      groth_verify,
      redeemer
    )
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in merkelized_groth16"
  }
}