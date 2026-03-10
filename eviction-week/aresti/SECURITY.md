# ARES Protocol Security Analysis

This document outlines the specific security mitigations integrated into the ARES Protocol to defend against major smart contract vulnerabilities and economic governance attacks.

## 1. Reentrancy Protection
Reentrancy attacks allow a malicious contract to re-enter a protocol function before its initial execution finishes. 
- **Mitigation**: We enforce the `nonReentrant` modifier strictly on the core `ARESTreasury.sol`'s `execute` function. 
- **Proof**: If a malicious payload is successfully voted into the `Queue` and executed, its fallback cannot retroactively drain the Treasury, as the `ReentrancyGuard` will immediately revert the re-entrant call.

## 2. Flash-Loan Governance Defenses
A classic vulnerability allows an attacker to flash-loan millions of governance tokens, vote, and repay the loan in the same transaction block.
- **Mitigation**: The `Proposer.sol` prevents this by querying past snapshots. When `castVote` is called, the voter's weight is determined strictly by `i_token.getPastVotes(msg.sender, proposal.voteStartedAt)`.
- **Proof**: Because flash loans must be borrowed and returned in the identical block, an attacker cannot inflate their balance at a historical `voteStartedAt` timestamp.

## 3. Large Treasury Drains
A compromised governance process might approve a proposal to transfer 100% of the $500M treasury tokens to a malicious actor.
- **Mitigation**: `ARESTreasury.sol` implements strict rate-limiting via `_checkRateLimit()`. We set `MAX_DAILY_WITHDRAWAL_BPS = 500` (5%).
- **Proof**: Even a perfectly valid `execute()` call originating from the `Queue` will be forcefully reverted if the payload attempts to withdraw more than 5% of the starting balance in a 24-hour period.

## 4. Cryptographic Authorization Attacks (Replay & Malleability)
EIP-712 signatures are susceptible to cross-chain replays, exact-transaction replays, and `s`-value malleability over the ECDSA curve.
- **Mitigation (Cross-Chain)**: `Authorizer.sol` includes `block.chainid` within the `DOMAIN_SEPARATOR`.
- **Mitigation (Replay)**: A strict mapping `mapping(address => uint256) private _nonces` forces atomic nonce increments upon successful signature consumption.
- **Mitigation (Malleability)**: Our custom `SignatureChecker.sol` directly enforces that `s` is located in the lower half of the secp256k1 curve (`s < 0x7FFFF...`), explicitly reverting `InvalidSignatureS()` if compromised.

## 5. Double Reward Claims
Contributors claiming rewards via `Distributor.sol` could hypothetically submit their Merkle proof twice.
- **Mitigation**: We utilize a `mapping(address => bool) private _claimed` variable.
- **Proof**: The first line of the `claim()` function checks `require(!_claimed[account], AlreadyClaimed());`, instantly blocking secondary extractions.

## 6. Proposal Griefing
An attacker could continually spam the `Proposer.sol` contract to overwhelm the execution queue.
- **Mitigation**: A `PROPOSAL_THRESHOLD` requires the proposer to possess at least 100,000 ARES tokens via a snapshot query `i_token.getPastVotes(proposer, block.timestamp - 1)` before creating a proposal.
