# Charms-Cardano: Optimization & Security Report

This is an in-depth analysis of the optimizations made to this codebase, as well as a review of the security considerations taken into account during the development process.

## Optimizations

There have been several optimizations made to the main contract design, mostly to simplify to help minimize the code size.

This is a commit-by-commit review of the changes made.

### Initial Commit: Unoptimized Implementation

- The initial implementation included several heavy components such as a fully-merkelized staking validator, unneccesary type checks and redundant data checks.

Main Script Size: 1,269 bytes

### Commit 9909169: Minimize main script implementation

- use `has_nft` instead of `has_nft_strict` in `has_beacon` function to reduce code size

  - This change reduces the number of checks performed when verifying the presence of an NFT, leading to a more efficient execution.
  - The strictness of the check was unnecessary for the security of the protocol. We assume that the presence of a beacon NFT guaranteees the correctness of the data, and rely on the governing contract/wallet to enforce this correctness.

- deduplicate the implementation across multiple script purposes

  - The script compiler was not effectively deduplicating the logic for different script purposes. This led to an inflated script size.
  - By consolidating the logic for different script purposes into a single implementation, we reduce code duplication and improve maintainability.
  - No change to the logic of the contract was made, only the structure of the code was altered. Security remains unchanged.

- don't require typing on unused parameters
  - Several variables were declared with explicit types but were not used in the logic of the contract.
  - By removing unnecessary type declarations, we reduce the overall code & script size.

Main Script Size: 730 bytes

### Commit c0adc58: Minimize even more
- replace merkelized validation with simpler withdraw-0 staking validation
    - reduces size, and opens door for further simplifications
    - security is still guaranteed by the inclusion of a redeemer for the staking validator referenced by the beacon input. If the withdrawal is not authorized, the redeemer will be orphaned and transaction will fail to validate.

- drop `input_arg` from redeemer
    - new design only needs charms version in redeemer. all other information is derived from scriptContext and parameters
    - since future versions will be dependent on zk-snarks over the normalized transaction, we do not expect to need generic information from the redeemer

Main Script Size: 690 bytes

### Commit 296b510: Remove check on withdraw redeemer as unnecessary

- removes an unnecessary type check on the withdraw redeemer
    - significantly reduces code size
    - we don't need to verify that the correct redeemer was selected - we check against a unique key hash for the staking validator, so if the redeemer is incorrect the transaction will fail to validate anyway

Main Script Size: 639 bytes

### Commit b3992da: Use ByteArray as the main script redeemer type

- changes the main script redeemer type from Int to ByteArray
    - reduces code size by avoiding unnecessary conversions

Main Script Size: 584 bytes

TODO

## Further Security Considerations

TODO