use ak_381/groth16.{SnarkVerificationKey, Proof}

pub type SpellRedeemer {
  spell_vk: SnarkVerificationKey
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