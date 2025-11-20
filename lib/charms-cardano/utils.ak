use aiken/collection/list
use aiken/primitive/bytearray
use cardano/assets.{Value, has_nft}
use charms_cardano/beacon.{BeaconParts}

pub fn bytearray_to_list(ba: ByteArray) -> List<Int> {
  bytearray.foldr(
    ba,
    [],
    fn(b: Int, acc: List<Int>) -> List<Int> { list.push(acc, b) },
  )
}

test bal() {
  bytearray_to_list(#[10, 255, 30, 98]) == [10, 255, 30, 98]
}

// only assets allowed in the beacon output are ada & 1 beacon NFT
pub fn has_beacon(beacon: BeaconParts, version: Int, value: Value) {
  has_nft(value, beacon.policy_id, mk_beacon_tn(beacon, version))
}

pub fn mk_beacon_tn(beacon: BeaconParts, version: Int) -> ByteArray {
  bytearray.concat(beacon.tx_prefix, bytearray.push(beacon.tx_suffix, version))
}
