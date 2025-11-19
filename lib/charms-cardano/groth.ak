use ak_381/groth16.{Proof, SnarkVerificationKey}

pub type Groth16Inputs {
  spell_vk: SnarkVerificationKey,
  proof: Proof
}

// simply downcast Data to Groth16Inputs & crash on exit
pub fn groth16_input_coercer(d: Data) -> Groth16Inputs {
    expect inputs: Groth16Inputs = d
    inputs
}