use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{Certificate}
use cardano/governance.{ProposalProcedure, Voter}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{OutputReference, Transaction}

validator merkelized_groth16 {
  withdraw(_redeemer: Data, _account: Credential, _self: Transaction) {
    todo @"withdraw logic goes here"
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in merkelized_groth16"
  }
}
