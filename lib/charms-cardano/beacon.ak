use aiken/crypto.{ScriptHash}

pub type BeaconParts {
    policy_id: ScriptHash,
    tx_prefix: ByteArray,
    tx_suffix: ByteArray,
}

pub type BeaconDatum {
    withdraw_credential: ScriptHash,
}