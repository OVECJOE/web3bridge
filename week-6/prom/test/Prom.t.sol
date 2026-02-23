// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Prom} from "../src/Prom.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract PromTest is Test {
    Prom public immutable prom;

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        MockERC20 mockToken = new MockERC20("Mock Token", "MTK", 18);
        prom = new Prom(address(mockToken));

        owner = address(this);
        user1 = makeAddr("User1");
        user2 = makeAddr("User2");

        // Deal some ether to users for testing
        vm.deal(user1, 10000 ether);
        vm.deal(user2, 10000 ether);

        // Mint some mock tokens
        mockToken.mint(user1, 1000e18);
        mockToken.mint(user2, 1000e18);

        // Approve Prom contract to spend users tokens
        vm.prank(user1);
        mockToken.approve(owner, mockToken.balanceOf(user1));
        vm.prank(user2);
        mockToken.approve(owner, mockToken.balanceOf(user2));
    }
}
