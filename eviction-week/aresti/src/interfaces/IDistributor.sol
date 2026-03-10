// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IDistributor {
    error AlreadyClaimed();
    error InvalidProof();
    error UnauthorizedRootUpdate();

    event Claimed(address indexed account, uint256 amount);
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    function updateMerkleRoot(bytes32 newRoot) external;

    function isClaimed(address account) external view returns (bool);

    function currentMerkleRoot() external view returns (bytes32);
}
