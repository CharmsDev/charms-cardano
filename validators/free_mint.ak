use aiken/collection/list
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction, placeholder}

validator free_mint(permissioned_vk: ByteArray, _app_vk: ByteArray) {
  mint(_redeemer: Data, _policy_id: PolicyId, self: Transaction) {
    list.has(self.extra_signatories, permissioned_vk)
  }

  else(_) {
    fail @"invalid use of free_mint"
  }
}

test free_mint_pass() {
  let permissioned_vk = #"deadbeef"
  let redeemer = ""
  let policy_id = #"deadbeef"
  let tx = Transaction { ..placeholder, extra_signatories: [permissioned_vk] }
  free_mint.mint(permissioned_vk, #"", redeemer, policy_id, tx)
}

test free_mint_fail() {
  let permissioned_vk = #"deadbeef"
  let redeemer = ""
  let policy_id = #"deadbeef"
  let tx = placeholder
  !free_mint.mint(permissioned_vk, #"", redeemer, policy_id, tx)
}
