use aiken/crypto.{ScriptHash}
use ak_381/groth16.{Proof, SnarkVerificationKey}
use cardano/address.{from_script}
use cardano/assets.{from_asset}
use cardano/transaction.{InlineDatum, Output}
use charms_cardano/beacon.{BeaconDatum, BeaconParts, beacon_asset_name}

pub type TestCircuit {
  sh: ScriptHash,
  vk: SnarkVerificationKey,
  proof: Proof,
  public_values: List<Int>,
}

pub const test_charms_version = "67"

pub const test_beacon_parts: BeaconParts =
  BeaconParts {
    policy_id: #"fe7c7867b321f41c674ef6c1af7b3250a673c24e4213e0425a7ae456",
    // token minting policy (not legit)
    name_prefix: "222",
    name_suffix: "deadbeef",
  }

pub fn base_passing_circuit() -> TestCircuit {
  let sh: ScriptHash =
    #"f5f1a4c8b3e6e2c3d4b5a69788796a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e0f"

  //  Template of VK
  let vk: SnarkVerificationKey =
    SnarkVerificationKey {
      nPublic: 2,
      vkAlpha: #"8e3d9e248feda194cb6fa0a3b64fd2a380cb5e94836bf8148bf97ebcbb5819d9a78f63102f0293c104bcbb2f810d8eb4",
      vkBeta: #"8cd68a7186a908212680a0234d8210c20328f8fb3ce1d69c9aec9330a5802d6cfaf6d7cf3176133221c19188590cb4141874ea7bbfcb9872931e115d882c46b90c3dcbcee10062d1c9b9b0a691d7bec7d2735f06495c7f71dea210e55b2782df",
      vkGamma: #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
      vkDelta: #"938231fcec443fbdeb1079ff126b8f69bd8579ffe82d39923214d4345395beee60200288fa20c97ae50f3212131b6f8802af2f9f515c65af6a9a6c294c738590104376a0af44731d6699db6a286608774243f7d1dddc4605eb340e65e15060a5",
      vkAlphaBeta: [
        #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
      ],
      vkIC: [
        #"b5813c90d3455acb8608fdf66e8601f24ef048f3fdf9384862d77c72cb5cddfde2b307976b1b0319c42ba985f94be60a",
        #"a41a0e6370c054be0f9acce08e97f6d5702d9daa9e9a934e8a377f553593baa1c58062adc73d63558653422d54d6f50c",
        #"8e02a87c519c3145f984d25fdf769f74fbc36626c385d4554fb4bc1d7a12cbf669d40f257023b8b3c9a31e631aa8f981",
      ],
    }

  //  Template of Proof
  let proof: Proof =
    Proof {
      piA: #"8b84d092731c653b1accdda79c51e3f5d289bed7311189d927deadef0470e437e6d1d400634726512a79a015867424e3",
      piB: #"92cb1c125816e4b522c7f430a5d74a61116b6189de7b2341f040194c02f10d9ef0cf081f4029444a65ea74e69d98b1cf08d3864087d5d2dee2ed6ab102f9b78e65d341f0824341a9fc25d0ea9dacccc5d355b4eddb0057949370a19c47135b0e",
      piC: #"a4ef633c858a3ff194db50eacdf715f7296fb3d1202c54b543284e9656b69aa90f33ac0e2572d3ab847b88268dcd1f7e",
    }
  // Template of public values
  let public_values: List<Int> = [561, 3]

  TestCircuit { sh, vk, proof, public_values }
}

pub fn test_beacon() -> Output {
  Output {
    address: from_script(base_passing_circuit().sh),
    value: from_asset(
      test_beacon_parts.policy_id,
      beacon_asset_name(test_beacon_parts, test_charms_version),
      1,
    ),
    datum: InlineDatum(
      BeaconDatum { withdraw_credential: base_passing_circuit().sh },
    ),
    reference_script: Some(base_passing_circuit().sh),
  }
}

pub type SchnorrComponents {
  signature: ByteArray,
  message: ByteArray,
  vkey: ByteArray,
}

pub const test_schnorr_components: SchnorrComponents = SchnorrComponents{
  signature: #"6D461BEB2F2DA00027D884FD13A24E2AE85CAECCA8AAA2D41777217EC38FB4960A67D47BC4F0722754EDB0E9017072600FFE4030C2E73771DCD3773F46A62652",
  message: #"243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89",
  vkey: #"DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659" 
}