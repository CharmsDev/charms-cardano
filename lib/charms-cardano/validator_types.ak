use aiken/crypto.{ScriptHash}

pub type WithdrawInputs {
    redeemer: Data
}

pub type BeaconDatum {
    withdraw_credential: ScriptHash,
}