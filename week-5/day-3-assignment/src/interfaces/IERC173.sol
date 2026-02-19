// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IERC173 {
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    function owner() external view returns (address _owner);
    function transferOwnership(address _newOwner) external;
}
