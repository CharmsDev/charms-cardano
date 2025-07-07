use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{Certificate}
use cardano/governance.{ProposalProcedure, Voter}
use cardano/transaction.{Transaction, OutputReference}
use cardano/script_context.{ScriptContext}

validator main {
  mint(_redeemer: Data, _policy_id: PolicyId, _self: Transaction) {
    todo @"mint logic goes here"
  }

  spend(_datum: Option<Data>, _redeemer: Data, _utxo: OutputReference, _self: Transaction) {
    todo @"spend logic goes here"
  }

  burn(_redeemer: Data, _policy_id: PolicyId, _self: Transaction) {
    todo @"burn logic goes here"
  }

  else(_ctx: ScriptContext) {
    todo @"fallback logic if none of the other purposes match"
  }
}
