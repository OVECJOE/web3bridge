// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IERC20 } from "./IERC20.sol";

contract SaveEther {
    mapping(address => uint256) public etherBalances;
    mapping(address => mapping(address => uint256)) public erc20Balances;

    event DepositSuccessful(address indexed sender, uint256 indexed amount, string tokenType);
    event WithdrawalSuccessful(address indexed receiver, uint256 indexed amount, string tokenType, bytes data);

    function depositEther() external payable {
        // require(msg.sender != address(0), "Address zero detected");
        require(msg.value > 0, "Can't deposit zero value");

        etherBalances[msg.sender] = etherBalances[msg.sender] + msg.value;

        emit DepositSuccessful(msg.sender, msg.value, "Ether");
    }

    function depositERC20(address _tokenAddress, uint256 _amount) external {
        IERC20 token = IERC20(_tokenAddress);
        require(_amount > 0, "Can't deposit zero value");

        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        erc20Balances[msg.sender][_tokenAddress] += _amount;

        emit DepositSuccessful(msg.sender, _amount, "ERC20");
    }

    function withdrawEther(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero detected");
        require(etherBalances[msg.sender] >= _amount, "Insufficient funds");

        etherBalances[msg.sender] -= _amount;

        (bool result, bytes memory data) = payable(msg.sender).call{value: _amount}("");
        require(result, "transfer failed");

        emit WithdrawalSuccessful(msg.sender, _amount, "Ether", data);
    }

    function withdrawERC20(address _tokenAddress, uint256 _amount) external {
        require(msg.sender != address(0), "Address zero");
        require(erc20Balances[msg.sender][_tokenAddress] >= _amount, "Insufficient funds");

        IERC20 token = IERC20(_tokenAddress);
        erc20Balances[msg.sender][_tokenAddress] -= _amount;

        require(token.transfer(msg.sender, _amount), "Transfer failed");
        emit WithdrawalSuccessful(msg.sender, _amount, "ERC20", "");
    }

    function getEtherBalance() external view returns (uint256) {
        return etherBalances[msg.sender];
    }

    function getERC20Balance(address tokenAddress) external view returns (uint256) {
        return erc20Balances[msg.sender][tokenAddress];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
    fallback() external {}
}
