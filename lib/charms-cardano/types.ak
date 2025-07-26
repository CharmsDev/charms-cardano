use ak_381/groth16.{SnarkVerificationKey, Proof}

pub type Groth16Inputs {
  vk: SnarkVerificationKey,
  proof: Proof,
  public_values: List<Int>,
}

pub fn groth16_input_coercer(d: Data) -> Groth16Inputs {
    expect inputs: Groth16Inputs = d
    inputs
}