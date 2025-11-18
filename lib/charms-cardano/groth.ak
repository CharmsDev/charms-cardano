use ak_381/groth16.{Proof}

pub type Groth16Inputs {
  proof: Proof,
  public_values: List<Int>,
}

// simply downcast Data to Groth16Inputs & crash on exit
pub fn groth16_input_coercer(d: Data) -> Groth16Inputs {
    expect inputs: Groth16Inputs = d
    inputs
}