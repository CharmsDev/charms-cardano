use aiken/crypto.{ScriptHash}
use ak_381/groth16.{Proof, SnarkVerificationKey}
use cardano/address.{from_script}
use cardano/assets.{from_asset}
use cardano/transaction.{InlineDatum, Output}
use charms_cardano/beacon.{BeaconDatum, BeaconParts, beacon_asset_name}
use charms_cardano/charms.{NormalizedSpell}

// Groth Utils

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

  // Real mock-prover VK from CharmsDev/charms MockProver DummyCircuit 
  let vk: SnarkVerificationKey =
    SnarkVerificationKey {
      nPublic: 1,
      vkAlpha: #"8fda482e4d7d7cfe718413cd03a290e7f48e6d18867caf21e74f594eedeead1ab2ccf6bf0ed52c492f683f27d6c72861",
      vkBeta: #"95d2ebb1584d1fc5c7e839cb5a2fdeb0c93da725ab2e89dc9f14d31ec3fd7a54c11b02df84e197ab492c02804b9d68b00a4aafdfdee1356d7089291430753ddc48bbe3dfee5677d9016b14645db6a1a623063b2c2261f53625d3bc80a6839dca",
      vkGamma: #"a604b708bc781ae38a361b93451384c060e8865aff71dbefee8326798aab2bfea23775cc734de87c275c5ff8648ec1300dd0d7c6d60ac00708ff7db2c274f8bcf99c710a010e41a0221d9fa6582f8ab41f299a1daa65cdf007aef54c6f623dde",
      vkDelta: #"ae3e7a8c90ba5b5e266fea7105f5d374324ad0e72809aeeda144ffba7defff7d45169d6f7e3c781dba158e67256dc98e18b219a74108de96a9519a60d0b71d6edfa740f665e34c84d83ce7d5ca555ae1cc54e5306295df8b9ffbb9f638117fb4",
      vkAlphaBeta: [
        // Dead field - groth_verify ignores this and recomputes e(alpha,beta) live
        #"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      ],
      vkIC: [
        #"9404936cde6bd34242ed397e1cbb20cbb8c708e616c63e326caaadcd4cfbd13506d5d16a294cf12528c931e766701cfe",
        #"a2d72c8535137e081100d44ec28bd6a0539637f4f29450ab6112d756259299f81d4ce6ef16c0bf4807a3ded9f8a8b8e5",
      ],
    }

  // Real mock-prover proof from CharmsDev/charms MockProver DummyCircuit
  // Generated for spell = { version: 7, tx: ([], []), app_public_inputs: [], mock: True }
  let proof: Proof =
    Proof {
      piA: #"8cb4da5f22a2e3058870ad0369f89b7e063ae5faa15584435df1ea1f85fef1f7e37bc74d5cf418f8c3deff7e384934b5",
      piB: #"82321e01f3b7ed62c1e908dfd3f43e97932f523827651eae06f1a502437ecd13fd8451ade4d384215cce1d79e28bca500918b11d21ee827e274a65b515d32e087c8fedfd723af03852da22b3c8601a9cea6847fbd2e19d576d5c1783e80aff62",
      piC: #"b50ff81beda7f1a5c3f77b785f3c4973b8711b2c0e23869ddf45807482ef28b91e43422efe6b5a1d17e4f24b17b6747b",
    }
  // SHA256(Plutus serialise_data((spell_vk, spell))) mod BLS12-381 scalar field order
  let public_values: List<Int> =
    [
      41978872024384238213921674269438459460353496601843866169862833818810829177629,
    ]

  TestCircuit { sh, vk, proof, public_values }
}

pub fn test_beacon(withdraw_sh: ScriptHash) -> Output {
  Output {
    address: from_script(base_passing_circuit().sh),
    value: from_asset(
      test_beacon_parts.policy_id,
      beacon_asset_name(test_beacon_parts, test_charms_version),
      1,
    ),
    datum: InlineDatum(BeaconDatum { withdraw_credential: withdraw_sh }),
    reference_script: Some(withdraw_sh),
  }
}

// Returns the exact NormalizedSpell used in CharmsDev/charms MockProver
// that corresponds to the mock proof fixtures in base_passing_circuit()
pub fn mock_normalized_spell() -> NormalizedSpell {
  NormalizedSpell {
    version: 7,
    tx: ([], []),
    // Empty transaction: (ins: [], outs: [])
    app_public_inputs: [],
    // Empty app_public_inputs
    mock: True,
  }
}

pub type SchnorrComponents {
  signature: ByteArray,
  message: ByteArray,
  vkey: ByteArray,
}

pub const test_schnorr_components: SchnorrComponents =
  SchnorrComponents {
    signature: #"6d461beb2f2da00027d884fd13a24e2ae85caecca8aaa2d41777217ec38fb4960a67d47bc4f0722754edb0e9017072600ffe4030c2e73771dcd3773f46a62652",
    message: #"243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c89",
    vkey: #"dff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659",
  }
