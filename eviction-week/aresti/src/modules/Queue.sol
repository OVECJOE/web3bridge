// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IQueue} from "../interfaces/IQueue.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract Queue is IQueue {
    TimelockController public immutable timelock;
    address public proposer;

    bytes32[] private _queueTracker;
    uint256 private _head;
    uint256 private _tail;

    error NotProposer();
    error QueueEmpty();
    error TimelockNotReady();

    modifier onlyProposer() {
        require(msg.sender == proposer, NotProposer());
        _;
    }

    constructor(
        uint256 minDelay,
        address[] memory executors,
        address admin
    ) {
        address[] memory thisContractArray = new address[](1);
        thisContractArray[0] = address(this);
        
        timelock = new TimelockController(minDelay, thisContractArray, executors, admin);
    }

    function setProposer(address _proposer) external {
        require(proposer == address(0), "Proposer already set");
        proposer = _proposer;
    }

    function queueProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        string calldata description
    ) external onlyProposer returns (bytes32 id) {
        bytes32 salt = keccak256(bytes(description));
        bytes32 predecessor = bytes32(0);
        
        if (_tail > _head) {
            predecessor = _queueTracker[_tail - 1];
        }

        timelock.scheduleBatch(
            targets,
            values,
            payloads,
            predecessor,
            salt,
            timelock.getMinDelay()
        );

        id = timelock.hashOperationBatch(targets, values, payloads, predecessor, salt);

        _queueTracker.push(id);
        _tail++;
    }

    function executeNext(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        string calldata description
    ) external payable {
        require(!isQueueEmpty(), QueueEmpty());

        bytes32 id = _queueTracker[_head];
        bytes32 predecessor = _head > 0 ? _queueTracker[_head - 1] : bytes32(0);
        bytes32 salt = keccak256(bytes(description));

        require(id == timelock.hashOperationBatch(targets, values, payloads, predecessor, salt), "Payload mismatch");
        require(timelock.isOperationReady(id), TimelockNotReady());

        timelock.executeBatch{value: msg.value}(targets, values, payloads, predecessor, salt);

        _head++;
    }

    function getNextId() external view returns (bytes32) {
        require(!isQueueEmpty(), QueueEmpty());
        return _queueTracker[_head];
    }

    function isQueueEmpty() public view returns (bool) {
        return _head == _tail;
    }

    function getQueueLength() external view returns (uint256) {
        return _tail - _head;
    }
}
