// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IDistributor} from "../interfaces/IDistributor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Distributor is IDistributor {
    IERC20 public immutable i_token;
    address public immutable i_queue;

    bytes32 private _merkleRoot;
    mapping(address => bool) private _claimed;

    modifier onlyQueue() {
        _onlyQueue();
        _;
    }

    function _onlyQueue() internal view {
        require(msg.sender == i_queue, UnauthorizedRootUpdate());
    }

    constructor(address _token, address _queue) {
        i_token = IERC20(_token);
        i_queue = _queue;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!_claimed[account], AlreadyClaimed());

        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(MerkleProof.verify(merkleProof, _merkleRoot, node), InvalidProof());

        _claimed[account] = true;
        
        require(i_token.transfer(account, amount), "Transfer failed");

        emit Claimed(account, amount);
    }

    function updateMerkleRoot(bytes32 newRoot) external onlyQueue {
        bytes32 oldRoot = _merkleRoot;
        _merkleRoot = newRoot;
        emit MerkleRootUpdated(oldRoot, newRoot);
    }

    function isClaimed(address account) external view returns (bool) {
        return _claimed[account];
    }

    function currentMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }
}
