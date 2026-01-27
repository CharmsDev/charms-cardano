use aiken/builtin.{verify_schnorr_secp256k1_signature}
use cardano/address.{Credential, Script}
use cardano/certificate.{Certificate}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction, placeholder}
use charms_cardano/test_utils.{test_schnorr_components}

validator staking_scrolls(vkey: ByteArray) {
  withdraw(redeemer: ByteArray, _account: Credential, self: Transaction) {
    verify_schnorr_secp256k1_signature(vkey, self.id, redeemer)
  }

  publish(_redeemer: ByteArray, _certificate: Certificate, _self: Transaction) {
    // Allow registration/deregistration without signature verification
    True
  }

  else(_ctx: ScriptContext) {
    fail @"scrolls validation has failed"
  }
}

test staking_scrolls_pass() {
  let placeholder_cred =
    Script(#"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction =
    Transaction { ..placeholder, id: test_schnorr_components.message }

  staking_scrolls.withdraw(
    test_schnorr_components.vkey,
    test_schnorr_components.signature,
    placeholder_cred,
    transaction,
  )
}

test staking_scrolls_bad_sig() fail {
  let signature =
    #"6d461beeef2da00027d884fd13a24e2ae85caecca8aaa2d41777217ec38fb4960a67d47bc4f0722754edb0e9017072600ffe4030c2e73771dcd3773f46a62652"
  let placeholder_cred =
    Script(#"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction =
    Transaction { ..placeholder, id: test_schnorr_components.message }

  staking_scrolls.withdraw(
    test_schnorr_components.vkey,
    signature,
    placeholder_cred,
    transaction,
  )
}

test staking_scrolls_bad_vkey() fail {
  let vkey = #"dff1d77f2a671c5f36183726db2341beeefeae1da2deced843240f7b502ba659"
  let placeholder_cred =
    Script(#"b33f6443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction =
    Transaction { ..placeholder, id: test_schnorr_components.message }

  staking_scrolls.withdraw(
    vkey,
    test_schnorr_components.signature,
    placeholder_cred,
    transaction,
  )
}
