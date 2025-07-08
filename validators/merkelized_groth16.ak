use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}
use ak_381/groth16.{SnarkVerificationKey, Proof, groth_verify}
use aiken_design_patterns/merkelized_validator.{WithdrawRedeemer}

type Groth16Redeemer {
  vk: SnarkVerificationKey,
  pk: Proof,
  public_values: List<Int>,
}

validator merkelized_groth16 {
  withdraw(redeemer: WithdrawRedeemer<Groth16Redeemer>, _account: Credential, _self: Transaction) {
    /// Extract parameters from the redeemer & run groth 16 validation
    merkelized_validator.withdraw(
      groth_verify,
      redeemer
    )    
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in merkelized_groth16"
  }
}