use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{Certificate}
use cardano/governance.{ProposalProcedure, Voter}
use cardano/transaction.{Transaction, OutputReference}
use cardano/script_context.{ScriptContext}

validator lock {

  spend(_datum: Option<Data>, _redeemer: Data, _utxo: OutputReference, _self: Transaction) {
    todo @"spend logic goes here"
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in lock"
  }
}
