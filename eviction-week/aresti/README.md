# ARES Protocol

A highly defensive, custom-built treasury execution protocol managing $500M+ in autonomous assets. Built strictly for secure execution, voting, and reward distribution without blindly inheriting unprotected boilerplate.

## Protocol Specification: Governance Lifecycle

The entire life cycle of a protocol action travels through four distinct phases designed to ensure maximal time for consensus, rigorous cryptographic authorization, and robust execution delays.

### Phase 1: Creation (Pending)
A governance token holder with sufficient past balance (min. 100,000 ARES tokens) submits a transaction payload using `proposer.propose()` or delegates the action off-chain using an EIP-712 signature via `proposer.proposeBySig()`. The proposal is assigned a strict cryptographic hash. It remains in a `Pending` state for exactly 1 day (`VOTING_DELAY`). This delay is critical as it sets an unchangeable snapshot in the token's clock history, preempting flash-loan attacks.

### Phase 2: Consensus (Active)
After the 1-day delay, the proposal status becomes `Active` for 3 continuous days (`VOTING_PERIOD`). Token holders call `castVote()` with their weight mathematically derived from the block timestamp of the `voteStartedAt` snapshot. Votes can be in favor (1) or against (0).

### Phase 3: Committal (Queued)
If a proposal successfully bypasses quorum requirements (400,000 ARES absolute) and `forVotes > againstVotes` upon the closure of the voting period, anyone can call `queue()`. This action pipes the exact authorized payload into the true FIFO `Queue` module, initiating an immutable 2-day Timelock delay.

### Phase 4: Execution (Executed)
Once the absolute Eta has matured in the queue, `proposer.execute()` is called. The `Queue` unlocks the internal Timelock wrappers, feeding the ABI-encoded payload directly into the `ARESTreasury`. The treasury processes the raw call tree, transferring assets or interacting with external contracts, while maintaining a strict 5% daily extraction rate limit.
