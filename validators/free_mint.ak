use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction, placeholder}

validator free_mint(_app_vk: ByteArray) {
  mint(_redeemer: Data, _policy_id: PolicyId, _self: Transaction) {
    True
  }

  else(_) {
    fail @"invalid use of free_mint"
  }
}

test free_mint_pass() {
  let app_vk = #"deadbeef" // Example ByteArray; can be any valid ByteArray
  let redeemer = ""
  let policy_id = #"deadbeef"
  let tx = placeholder
  free_mint.mint(app_vk, redeemer, policy_id, tx)
}
