// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TaultFactory} from "../src/TaultFactory.sol";
import {Tault} from "../src/Tault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TaultFactoryTest is Test {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant impersonatedUser =
        0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE;
    // address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    TaultFactory factory;

    function setUp() public {
        factory = new TaultFactory();
        console.log("Balance:", address(impersonatedUser).balance);
    }

    function test_CreateVaultForUSDC() public {
        deal(USDC, impersonatedUser, 1000e6);

        vm.startPrank(impersonatedUser);

        address vault = factory.createVault(USDC);
        IERC20(USDC).approve(vault, 500e6);
        Tault(vault).deposit(500e6);

        vm.stopPrank();

        assertEq(Tault(vault).totalLiquidity(), 500e6);
        assertEq(Tault(vault).balanceOf(impersonatedUser), 500e6);

        console.log("USDC Vault:", vault);
        console.log("NFT tokenURI:", factory.nft().tokenURI(0));
    }
}
