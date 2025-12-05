# Charms-Cardano: Overview

Charms are utxo-chain objects that are composed of native assets with attached data including app contracts which can include arbitrary data governing the behaviour of the assets. Because these apps function as a metaprotocol, the Charms themselves can operate across chains via Beaming transactions which lock funds until a proof can satisfy the unlock condition.

## Versions

### V1 - Scrolls ICP Charms

- Initial setup is done asynchronously involving transactions across both networks
- A consuming transaction is constructed for the target chain, with a proof that the apps rules have been satisfied
- The proof is passed to the ICP verifier
- The ICP verifier signs the transaction
- The transaction is submitted by the user & the ICP verifiers signature is confirmed by the Charms Scrolls contract

### V2 - ZKSnark-Secured Charms

- Initial setup is done asynchronously involving transactions across both networks
- A consuming transaction is constructed for the target chain, with a proof that the apps rules have been satisfied
- The transaction is submitted with the proof and verified trustlessly by the Charms ZKSnark contract

## Design

Charms validation is split into 3 modular components.

The technical specifics for each of these components can be found in corresponding files (TODO) in the `/spec` folder.

### Main

The main contract is responsible for handling the delegation of transaction validation to the appropriate script based on the required charms version.

### Delegated Validators

The delegated validators contain the actual logic for validating transactions based on the specific charms version. Each version has its own validator script that implements the necessary rules and conditions.

#### Scrolls Validator

The Srolls validator is responsible for verifying the signatures from the Scrolls ICP verifiers to ensure that the transaction has been approved by the trusted parties.

#### Groth16 Validator

The Groth16 validator is responsible for verifying zk-SNARK proofs using the Groth16 proving system to ensure that the transaction satisfies the app contract.

#### Future Validators

Future plans include support for additional zk-SNARK schemes such as Pari to enhance the performance of the Charms protocol.

### Beacon Token Minting Policy

The beacon token minting policy is responsible for managing the creation of beacon tokens that allow easy discoverability and verification of the delegated validators on-chain.
