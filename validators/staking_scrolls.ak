use aiken/builtin.{verify_schnorr_secp256k1_signature}
use cardano/address.{Credential, VerificationKey, Script}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction, placeholder}
use charms_cardano/test_utils.{test_schnorr_components}

validator staking_scrolls(vkey: ByteArray) {
  withdraw(redeemer: ByteArray, _account: Credential, self: Transaction) {
    verify_schnorr_secp256k1_signature(vkey, self.id, redeemer)
  }

  else(_ctx: ScriptContext) {
    fail @"scrolls validation has failed"
  }
}

test staking_scrolls_pass() {
  let placeholder_cred = Script(#"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction = Transaction { ..placeholder, id: test_schnorr_components.message }

  staking_scrolls.withdraw(
    test_schnorr_components.vkey,
    test_schnorr_components.signature,
    placeholder_cred,
    transaction,
  )
}

test staking_scrolls_bad_sig() fail {
  let signature = #"6D461BEEEF2DA00027D884FD13A24E2AE85CAECCA8AAA2D41777217EC38FB4960A67D47BC4F0722754EDB0E9017072600FFE4030C2E73771DCD3773F46A62652"
  let placeholder_cred = Script(#"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction = Transaction { ..placeholder, id: test_schnorr_components.message }

  staking_scrolls.withdraw(
    test_schnorr_components.vkey,
    signature,
    placeholder_cred,
    transaction,
  )
}

test staking_scrolls_bad_vkey() fail {
  let vkey = #"DFF1D77F2A671C5F36183726DB2341BEEEFEAE1DA2DECED843240F7B502BA659"
  let placeholder_cred = Script(#"b33f6443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction = Transaction { ..placeholder, id: test_schnorr_components.message }

  staking_scrolls.withdraw(
    vkey,
    test_schnorr_components.signature,
    placeholder_cred,
    transaction,
  )
}