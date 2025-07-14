use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{Certificate}
use cardano/governance.{ProposalProcedure, Voter}
use cardano/transaction.{Transaction, OutputReference}
use cardano/script_context.{ScriptContext}

validator free_mint(utxo_ref: OutputReference) {

  mint(_redeemer: Data, _policy_id: PolicyId, _self: Transaction) {
    True
  }

  burn(_datum: Option<Data>, _redeemer: Data, _utxo: OutputReference, _self: Transaction) {
    True
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in free_mint"
  }
}