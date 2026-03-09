// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";

contract EvictionVaultTest is Test {
    EvictionVault public vault;
    address[] public signers;

    event Deposit(address indexed, uint256);

    function setUp() public {
        signers.push(makeAddr("alice"));
        signers.push(makeAddr("bob"));
        signers.push(makeAddr("charlie"));

        hoax(signers[0], 400 ether);
        vault = new EvictionVault{value: 10 ether}(signers, 3);
    }

    function testSetupIsCorrect() public view {
        vm.assertEq(vault.signersCount(), signers.length);
        vm.assertEq(vault.threshold(), 3);
        vm.assertEq(vault.owner(), signers[0]);
    }

    function testContractReceivedEtherOnSetup() public view {
        vm.assertEq(vault.totalVaultValue(), 10 ether);
    }

    function testDepositIncreasesSignerBalance() public {
        hoax(signers[1], 5 ether);
        vault.deposit{value: 2 ether}();
        vm.assertEq(vault.balances(signers[1]), 2 ether);
        vm.assertGt(vault.totalVaultValue(), 10 ether);
    }

    function testDepositEmitEventAfterCompletion() public {
        vm.prank(signers[0]);
        vm.expectEmit(true, true, true, false);
        emit Deposit(signers[0], 2 ether);
        vault.deposit{value: 2 ether}();
    }

    function testWithdrawDeductsFromSignerBalance() public {
        vm.prank(signers[0]);
        vault.withdraw(2 ether);
        vm.assertEq(vault.balances(signers[0]), 8 ether);
        vm.assertEq(vault.totalVaultValue(), 8 ether);
    }
}
