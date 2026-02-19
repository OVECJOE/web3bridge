// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {SMS} from "../src/SMS.sol";

contract SMSTest is Test {
    MockERC20 token;
    SMS sms;

    address owner;
    address alice; // parent
    address bob; // staff

    function setUp() public {
        owner = address(this);
        token = new MockERC20("Mock Token", "MTK", 18);
        sms = new SMS();

        token.mint(owner, 1000e18);
        token.approve(address(sms), type(uint256).max);

        // Set up test accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Mint tokens to Alice and Bob
        token.mint(alice, 100e18);
        token.mint(bob, 10e18);

        // Add token to SMS
        sms.addSupportedToken(address(token), token.symbol(), token.decimals());
    }
}
