// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IARESTreasury {
    error Unauthorized();
    error TransferFailed();
    error RateLimitExceeded();

    event Executed(address indexed target, uint256 value, bytes payload);

    function execute(
        address target,
        uint256 value,
        bytes calldata payload
    ) external returns (bytes memory);
}
