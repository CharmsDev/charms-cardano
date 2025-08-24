use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}

validator free_mint(_app_vk: ByteArray) {
  mint(_redeemer: Data, _policy_id: PolicyId, _self: Transaction) {
    True
  }

  else(_) {
    fail @"invalid use of free_mint"
  }
}
