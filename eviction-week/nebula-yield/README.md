# EvictionVault Revamp

This repository contains the `EvictionVault` project. The original `EvictionVault` contract [found here](https://gist.github.com/Goodness5/ede905f58c5a817d85d0fe3bd0091945) contained several critical security vulnerabilities and bad practices. Below is a detailed breakdown of the vulnerabilities identified in the old code and how they were mitigated in the revamped version (`EvictionVault.sol`).

## Security Vulnerabilities & Fixes

### 1. Missing Access Control on Critical Functions
- **Vulnerability**: In the original contract, the `setMerkleRoot` and `emergencyWithdrawAll` functions lacked any access control, allowing any address to modify the Merkle root or drain the entire vault.
- **Fix**: The contract now inherits from OpenZeppelin's `Ownable`, and these functions are restricted with the `onlyOwner` modifier.

### 2. `tx.origin` Authorization Phishing
- **Vulnerability**: The `receive` fallback function previously used `tx.origin` to credit deposits (`balances[tx.origin] += msg.value;`), which is vulnerable to phishing attacks where a malicious contract acts as a middleman.
- **Fix**: Replaced `tx.origin` with `msg.sender` in the `deposit()` function, and routed `receive()` directly to `this.deposit()`.

### 3. Usage of `.transfer()` Over `.call{value: ...}("")`
- **Vulnerability**: The old `withdraw` and `claim` functions used `payable(...).transfer(amount)`, which forwards a fixed stipend of 2300 gas. This can fail if the receiving contract has a fallback function that consumes more gas, breaking compatibility with smart contract wallets.
- **Fix**: Refactored to use `(bool success, ) = payable(...).call{value: _amount}("");` with a requirement that checks the `success` boolean, ensuring forward-compatibility and safety against gas changes.

### 4. Poor Signature Verification Code
- **Vulnerability**: `verifySignature` incorrectly used a non-existent `MerkleProof.recover` method.
- **Fix**: Replaced with OpenZeppelin's `ECDSA.recover` to properly verify signed message hashes.

### 5. Weak Access Control for Pausing the Contract
- **Vulnerability**: Any owner/signer could pause or unpause the contract, leading to potential griefing or deadlocks.
- **Fix**: Leveraged OpenZeppelin's `Pausable` extension and restricted the `pause` and `unpause` functions to `onlyOwner`.

### 6. Missing Address(0) Validations
- **Vulnerability**: The `submitTransaction` function lacked a zero-address check for the `to` destination, meaning signatures could accidentally be gathered for burning funds.
- **Fix**: Added `require(_to != address(0), VaultLib.ZeroAddressDetection());`.

### 7. Gas Inefficiency & Custom Errors
- **Vulnerability**: The original contract used string revert messages like `"paused"` or `"no owners"`, which are gas-heavy. 
- **Fix**: Implemented a separate `VaultLib` library containing custom errors (e.g., `VaultLib.FailedTransaction()`, `VaultLib.NotASigner()`) to significantly reduce deployment and execution gas costs.

## Usage

### Build
```shell
$ forge build
```

### Test
```shell
$ forge test
```

### Deploy
```shell
$ forge script script/EvictionVault.s.sol:EvictionVaultScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
