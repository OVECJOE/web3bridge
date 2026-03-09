// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {VaultLib} from "./libraries/Vault.sol";

contract EvictionVault is Ownable, Pausable {
    // Constants
    uint256 public constant TIMELOCK_DURATION = 1 hours;

    // State Variables

    address[] public signers;
    mapping(address => bool) public isSigner;

    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => VaultLib.Transaction) public transactions;

    uint256 public txCount;

    mapping(address => uint256) public balances;

    bytes32 public merkleRoot;

    mapping(address => bool) public claimed;

    mapping(bytes32 => bool) public usedHashes;

    uint256 public totalVaultValue;

    constructor(
        address[] memory _signers,
        uint256 _threshold
    ) payable Ownable(msg.sender) {
        require(_signers.length > 0, VaultLib.InvalidArgument());
        threshold = _threshold;

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0));
            isSigner[signer] = true;
            signers.push(signer);
        }

        balances[msg.sender] = msg.value;
        totalVaultValue = msg.value;
    }

    function signersCount() external view returns (uint256) {
        return signers.length;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    receive() external payable {
        this.deposit();
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit VaultLib.Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external whenNotPaused {
        require(
            balances[msg.sender] >= _amount,
            VaultLib.InsufficientBalance()
        );

        balances[msg.sender] -= _amount;
        totalVaultValue -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, VaultLib.FailedTransaction());

        emit VaultLib.Withdrawal(msg.sender, _amount);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external whenNotPaused {
        require(isSigner[msg.sender], VaultLib.NotASigner());
        require(_to != address(0), VaultLib.ZeroAddressDetection());

        uint256 id = txCount++;
        transactions[id] = VaultLib.Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });

        confirmed[id][msg.sender] = true;
        emit VaultLib.Submission(id);
    }

    function confirmTransaction(uint256 _txId) external whenNotPaused {
        require(isSigner[msg.sender], VaultLib.NotASigner());

        VaultLib.Transaction storage txn = transactions[_txId];

        require(!txn.executed, VaultLib.AlreadyExecuted());
        require(!confirmed[_txId][msg.sender], VaultLib.AlreadyConfirmed());

        confirmed[_txId][msg.sender] = true;
        txn.confirmations++;

        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }

        emit VaultLib.Confirmation(_txId, msg.sender);
    }

    function executeTransaction(uint256 _txId) external whenNotPaused {
        VaultLib.Transaction storage txn = transactions[_txId];

        require(txn.confirmations >= threshold, VaultLib.NotEnoughSigners());
        require(!txn.executed, VaultLib.AlreadyExecuted());
        require(
            block.timestamp >= txn.executionTime,
            VaultLib.TransactionAlreadyExpired()
        );

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, VaultLib.FailedTransaction());
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        emit VaultLib.MerkleRootSet(root);
    }

    function claim(
        bytes32[] calldata _proof,
        uint256 _amount
    ) external whenNotPaused {
        bytes32 leaf;
        assembly {
            mstore(0x00, shl(96, caller()))
            mstore(0x14, _amount)
            leaf := keccak256(0x00, 52)
        }

        bytes32 computed = MerkleProof.processProof(_proof, leaf);

        require(computed == merkleRoot, VaultLib.InvalidMerkleProof());
        require(!claimed[msg.sender], VaultLib.AlreadyClaimed());

        claimed[msg.sender] = true;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, VaultLib.FailedTransaction());

        totalVaultValue -= _amount;
        emit VaultLib.Claim(msg.sender, _amount);
    }

    function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        return ECDSA.recover(messageHash, signature) == signer;
    }

    function emergencyWithdrawAll() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, VaultLib.FailedTransaction());
        totalVaultValue = 0;
    }
}
