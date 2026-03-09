// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library VaultLib {
    // Data structures
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    // Events
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);
    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);

    // Errors
    error NotOwner();
    error InvalidArgument();
    error InsufficientBalance();
    error FailedTransaction();
    error NotASigner();
    error ZeroAddressDetection();
    error AlreadyExecuted();
    error AlreadyConfirmed();
    error NotEnoughSigners();
    error TransactionAlreadyExpired();
    error InvalidMerkleProof();
    error AlreadyClaimed();
}
