use aiken/crypto.{ScriptHash}
use aiken/primitive/bytearray
use cardano/assets.{Value, has_nft}

pub type BeaconParts {
  policy_id: ScriptHash,
  name_prefix: ByteArray,
  name_suffix: ByteArray,
}

pub type BeaconDatum {
  withdraw_credential: ScriptHash,
}

pub fn has_beacon(beacon: BeaconParts, version: ByteArray, value: Value) {
  has_nft(value, beacon.policy_id, beacon_asset_name(beacon, version))
}

pub fn beacon_asset_name(beacon: BeaconParts, version: ByteArray) -> ByteArray {
  beacon.name_prefix
    |> bytearray.concat(version)
    |> bytearray.concat(beacon.name_suffix)
}
