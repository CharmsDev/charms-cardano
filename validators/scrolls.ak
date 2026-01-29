use aiken/builtin.{verify_schnorr_secp256k1_signature}
use cardano/address.{Credential, Script}
use cardano/certificate.{Certificate}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction, placeholder}
use charms_cardano/test_utils.{test_schnorr_components}

validator scrolls(vkey: ByteArray) {
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

test scrolls_verify_schnorr_signature() {
  // // BIP-340 test vector #0
  // // Private key: 0000000000000000000000000000000000000000000000000000000000000003
  // // Public key (x-only): F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9
  // // Message: 0000000000000000000000000000000000000000000000000000000000000000
  // // Signature: E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0
  // let vkey = #"f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9"
  // let txid = #"0000000000000000000000000000000000000000000000000000000000000000"
  // let signature =
  //   #"e907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca821525f66a4a85ea8b71e482a74f382d2ce5ebeee8fdb2172f477df4900d310536c0"

  // Scrolls
  let vkey = #"aa75665a675fc5bcbaded7b8ae8d833b07d3559ab352db6c83efd361392840cb"
  let txid = #"d21afcf98117329cb8ad034c9e1f712684cbec800b8129241f827ac9bc9f4027"
  let signature =
    #"2ce5f83a9a6691e952de9590b87c2389af6dad2c8880808a8d91468c9de94de50953e71c624c78cdbd7196291b33115d5df02ec87da191cce198af06cbc3f044"

  verify_schnorr_secp256k1_signature(vkey, txid, signature)
}

test scrolls_pass() {
  let placeholder_cred =
    Script(#"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction =
    Transaction { ..placeholder, id: test_schnorr_components.message }

  scrolls.withdraw(
    test_schnorr_components.vkey,
    test_schnorr_components.signature,
    placeholder_cred,
    transaction,
  )
}

test scrolls_bad_sig() fail {
  let signature =
    #"6d461beeef2da00027d884fd13a24e2ae85caecca8aaa2d41777217ec38fb4960a67d47bc4f0722754edb0e9017072600ffe4030c2e73771dcd3773f46a62652"
  let placeholder_cred =
    Script(#"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction =
    Transaction { ..placeholder, id: test_schnorr_components.message }

  scrolls.withdraw(
    test_schnorr_components.vkey,
    signature,
    placeholder_cred,
    transaction,
  )
}

test scrolls_bad_vkey() fail {
  let vkey = #"dff1d77f2a671c5f36183726db2341beeefeae1da2deced843240f7b502ba659"
  let placeholder_cred =
    Script(#"b33f6443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6")
  let transaction =
    Transaction { ..placeholder, id: test_schnorr_components.message }

  scrolls.withdraw(
    vkey,
    test_schnorr_components.signature,
    placeholder_cred,
    transaction,
  )
}
