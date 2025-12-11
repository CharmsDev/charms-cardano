use aiken/builtin.{verify_schnorr_secp256k1_signature}
use cardano/address.{Credential}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}

validator staking_scrolls(vkey: ByteArray) {
  withdraw(redeemer: ByteArray, _account: Credential, self: Transaction) {
    verify_schnorr_secp256k1_signature(vkey, self.id, redeemer)
  }

  else(_ctx: ScriptContext) {
    fail @"scrolls validation has failed"
  }
}
