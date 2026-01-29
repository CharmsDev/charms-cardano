use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Credential, Script}
use cardano/certificate.{Certificate, RegisterCredential}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction, placeholder}

validator scrolls(vkey_hash: VerificationKeyHash) {
  withdraw(_redeemer: Data, _account: Credential, self: Transaction) {
    self.extra_signatories |> list.has(vkey_hash)
  }

  publish(_redeemer: ByteArray, certificate: Certificate, _self: Transaction) {
    when certificate is {
      RegisterCredential { .. } -> True
      _ -> False
    }
  }

  else(_ctx: ScriptContext) {
    fail @"scrolls validation has failed"
  }
}

test scrolls_pass() {
  let vkey_hash = #"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6"
  let placeholder_cred = Script(vkey_hash)
  let transaction =
    Transaction { ..placeholder, extra_signatories: [vkey_hash] }

  scrolls.withdraw(vkey_hash, Void, placeholder_cred, transaction)
}

test scrolls_missing_signer() fail {
  let vkey_hash = #"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6"
  let other_vkey_hash =
    #"a1234567e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6"
  let placeholder_cred = Script(vkey_hash)
  let transaction =
    Transaction { ..placeholder, extra_signatories: [other_vkey_hash] }

  scrolls.withdraw(vkey_hash, Void, placeholder_cred, transaction)
}

test scrolls_no_signers() fail {
  let vkey_hash = #"b3346443e14de85048f2210d0d39cd38a7ddcd6839ee1630307e6af6"
  let placeholder_cred = Script(vkey_hash)
  let transaction = Transaction { ..placeholder, extra_signatories: [] }

  scrolls.withdraw(vkey_hash, Void, placeholder_cred, transaction)
}
