# ARES Protocol Architecture

The ARES Protocol is a highly secure, modular treasury execution protocol engineered to manage a massive $500M+ autonomous treasury. The architecture is deliberately fragmented into robust independent modules to minimize attack surfaces and provide granular control over the proposal lifecycle, execution queue, and reward distribution.

## Core Modules

### 1. Transaction Proposal System (`Proposer.sol`)
The `Proposer` module acts as the primary gateway for system governance. Instead of executing actions immediately, it rigorously enforces a complete "commit phase" and voting lifecycle.
- **Interactions**: Users submit proposals containing ABI-encoded payloads. The `Proposer` assigns a deterministic hash to each proposal, saving state costs by keeping raw call data off-chain.
- **Dependencies**: Interacts with the `IVotes` token for voting power snapshots, the `IAuthorizer` for cryptographic approval, and the `IQueue` for scheduling successful proposals.

### 2. Time-Delayed Execution Engine (`Queue.sol`)
The `Queue` is a custom-built FIFO structure ensuring precise execution order of approved payloads.
- **Interactions**: Only the `Proposer` module is authorized to schedule payloads into the `Queue`.
- **Dependencies**: The `Queue` wraps an internal instance of OpenZeppelin's `TimelockController`, fully decoupling time-delayed execution logic from governance tracking while providing an impenetrable FIFO guarantee. 

### 3. Cryptographic Authorization Layer (`Authorizer.sol` & `SignatureChecker.sol`)
The `Authorizer` validates EIP-712 structured signatures for off-chain approvals, enabling gasless proposal submissions via proxy.
- **Interactions**: Interacts with the `SignatureChecker` library to verify ECDSA recovery and reject malleable `s` values.
- **Dependencies**: Integrated securely into the `Proposer.sol` via the `proposeBySig` function, where nonces are strictly consumed exactly once per successful authorization.

### 4. Contributor Reward Distribution (`Distributor.sol`)
A highly optimized module using Merkle Trees to distribute airdrops and contributor rewards at scale without bloating contract state.
- **Interactions**: Users submit Merkle Proofs to claim tokens.
- **Dependencies**: Only the `Queue` (via Timelock execution) is authorized to update the authoritative `merkleRoot`.

### 5. Treasury Integration (`ARESTreasury.sol`)
This is the central vault holding the funds, purposely isolated from all governance and queues.
- **Interactions**: It only accepts and executes payloads passed directly from the `Queue`'s Timelock instance.
- **Dependencies**: Utilizes a rate-limiting architecture to prevent total treasury drains in a single day.

## System Workflow Diagram
1. User calls `Proposer.propose()` (or `proposeBySig()`).
2. After a mandatory `VOTING_DELAY`, voters cast weights based on past token snapshots.
3. If quorum and majority are reached, `Proposer.queue()` passes the payload to the `Queue`.
4. The `Queue` schedules the payload strictly after its predecessors.
5. Post-ETA, `Proposer.execute()` initiates the final call tree through `Queue` -> `ARESTreasury`.
