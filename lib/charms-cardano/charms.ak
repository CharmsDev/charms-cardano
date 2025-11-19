use ak_381/groth16.{SnarkVerificationKey, Proof}
use charms_cardano/utils.{bytearray_to_list}
use aiken/builtin.{serialise_data}
use cardano/transaction.{Datum, InlineDatum, NoDatum, DatumHash}

pub type SpellRedeemer {
  input_args: Data,
  charms_version: Int,
}

pub type SpellDatum {
  spell: NormalizedSpell,
  proof: Proof,
}

// from https://github.com/CharmsDev/charms/blob/82b3bf558c7b7e70df0574ede296aea2baf6e891/charms-client/src/lib.rs#L95
pub type NormalizedSpell {
  version: Int,
  tx: Data,
  app_public_inputs: Pairs<App, Data>,
  mock: Bool,
}

// from https://github.com/CharmsDev/charms/blob/82b3bf558c7b7e70df0574ede296aea2baf6e891/charms-data/src/lib.rs#L196
pub type App {
    tag: String,
    identity: ByteArray,
    vk: SnarkVerificationKey
}

pub fn cbor_serialize(spell_vk: SnarkVerificationKey, spell: NormalizedSpell) -> List<Int> {
  bytearray_to_list(serialise_data((spell_vk, spell)))
}

pub fn extract_spell(datum: Datum) -> Data {
  when datum is {
    NoDatum -> fail
    DatumHash(_h) -> fail
    // just fail with DatumHash for now
    // expect Some(d) = dict.get(tx_datums, h)
    // d
    InlineDatum(d) -> d
  }
}