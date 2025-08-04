use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction, OutputReference}
use cardano/script_context.{ScriptContext}

validator free_mint(_utxo_ref: OutputReference) {

  mint(_redeemer: Data, _policy_id: PolicyId, _self: Transaction) {
    True
  }

  else(_ctx: ScriptContext) {
    fail @"invalid redeemer in free_mint"
  }
}