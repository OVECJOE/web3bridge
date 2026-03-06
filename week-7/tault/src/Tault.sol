// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Tault {
    using SafeERC20 for IERC20;

    // Errors
    error InvalidAmount();
    error ZeroAddress();
    error InsufficientBalance();

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // State Variables
    IERC20 public immutable token;
    address public immutable factory;
    address public immutable creator;
    uint256 public totalLiquidity;
    mapping(address => uint256) public balanceOf;

    constructor(address _token, address _creator) {
        factory = msg.sender;

        require(_token != address(0), ZeroAddress());
        require(_creator != address(0), ZeroAddress());

        token = IERC20(_token);
        creator = _creator;
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, InvalidAmount());

        token.safeTransferFrom(msg.sender, address(this), _amount);
        totalLiquidity += _amount;
        balanceOf[msg.sender] += _amount;

        emit Deposited(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, InvalidAmount());
        require(balanceOf[msg.sender] >= _amount, InsufficientBalance());

        balanceOf[msg.sender] -= _amount;
        totalLiquidity -= _amount;

        token.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }
}
