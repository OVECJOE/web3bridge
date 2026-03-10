// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IAuthorizer {
    error InvalidSigner();
    
    function verifyAuth(
        address account,
        bytes32 structHash,
        bytes calldata signature
    ) external view;

    function consumeNonce(address account) external returns (uint256);

    function getNonce(address account) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
