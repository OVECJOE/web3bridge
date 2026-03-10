// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IQueue {
    function queueProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        string calldata description
    ) external returns (bytes32 id);

    function executeNext(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        string calldata description
    ) external payable;

    function getNextId() external view returns (bytes32);

    function isQueueEmpty() external view returns (bool);

    function getQueueLength() external view returns (uint256);
}
