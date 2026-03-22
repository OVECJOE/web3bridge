// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MeowelotToken} from "../src/MeowelotToken.sol";
import {MeowelotNFT} from "../src/MeowelotNFT.sol";

contract MeowelotTokenTest is Test {
    MeowelotToken public token;
    MeowelotNFT   public nft;

    address owner    = address(0x1);
    address treasury = address(0x2);
    address alice    = address(0x3);
    address bob      = address(0x4);
    address carol    = address(0x5);

    uint256 constant FAUCET_AMOUNT   = 1_000 * 1e18;
    uint256 constant ANTI_WHALE_CAP  = 200_000 * 1e18;
    uint256 constant MAX_SUPPLY      = 10_000_000 * 1e18;
    uint256 constant NFT_THRESHOLD   = 10_000 * 1e18;
    uint256 constant FAUCET_COOLDOWN = 24 hours;

    function setUp() public {
        vm.startPrank(owner);
        nft   = new MeowelotNFT(owner);
        token = new MeowelotToken(owner, treasury, address(nft));
        nft.setTokenContract(address(token));
        vm.stopPrank();
    }

    // ─── Basic deployment checks ─────────────────────────────────────────────
    function test_InitialState() public view {
        assertEq(token.name(), "Meowelot");
        assertEq(token.symbol(), "MEOW");
        assertEq(token.decimals(), 18);
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
        assertEq(token.balanceOf(owner), 5_000_000 * 1e18);
        assertEq(token.treasuryAddress(), treasury);
        assertEq(address(token.nftContract()), address(nft));
    }

    // ─── requestToken ─────────────────────────────────────────────────────────
    function test_RequestToken_Success() public {
        vm.prank(alice);
        token.requestToken();

        assertEq(token.balanceOf(alice), FAUCET_AMOUNT);
        assertEq(token.lastRequestTime(alice), block.timestamp);
    }

    function test_RequestToken_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit MeowelotToken.TokensRequested(alice, FAUCET_AMOUNT);
        vm.prank(alice);
        token.requestToken();
    }

    function test_RequestToken_CooldownReverts() public {
        vm.prank(alice);
        token.requestToken();

        vm.prank(alice);
        vm.expectRevert();
        token.requestToken();
    }

    function test_RequestToken_AfterCooldown_Succeeds() public {
        vm.prank(alice);
        token.requestToken();

        vm.warp(block.timestamp + FAUCET_COOLDOWN + 1);

        vm.prank(alice);
        token.requestToken();

        assertEq(token.balanceOf(alice), FAUCET_AMOUNT * 2);
    }

    function test_RequestToken_CooldownExactBoundary() public {
        vm.prank(alice);
        token.requestToken();

        // Exactly at cooldown — should still revert
        vm.warp(block.timestamp + FAUCET_COOLDOWN);
        vm.prank(alice);
        vm.expectRevert();
        token.requestToken();

        // One second later — should succeed
        vm.warp(block.timestamp + 1);
        vm.prank(alice);
        token.requestToken();
    }

    function test_RequestToken_IndependentPerUser() public {
        // Alice requests
        vm.prank(alice);
        token.requestToken();

        // Bob can still request (different cooldown tracker)
        vm.prank(bob);
        token.requestToken();

        assertEq(token.balanceOf(alice), FAUCET_AMOUNT);
        assertEq(token.balanceOf(bob), FAUCET_AMOUNT);
    }

    function test_RequestToken_GenesisTimestampStillHasCooldown() public {
        vm.warp(0);

        vm.prank(alice);
        token.requestToken();

        vm.prank(alice);
        vm.expectRevert();
        token.requestToken();
    }

    function test_RequestToken_TimeUntilNextRequest() public {
        assertEq(token.timeUntilNextRequest(alice), 0);

        vm.prank(alice);
        token.requestToken();

        uint256 remaining = token.timeUntilNextRequest(alice);
        assertApproxEqAbs(remaining, FAUCET_COOLDOWN, 5);

        vm.warp(block.timestamp + FAUCET_COOLDOWN + 1);
        assertEq(token.timeUntilNextRequest(alice), 0);
    }

    function test_RequestToken_AntiWhaleBlock() public {
        // Give alice just below the cap
        vm.prank(owner);
        token.transfer(alice, ANTI_WHALE_CAP - FAUCET_AMOUNT / 2);

        vm.prank(alice);
        vm.expectRevert(MeowelotToken.ExceedsAntiWhaleCap.selector);
        token.requestToken();
    }

    function test_RequestToken_BlacklistedReverts() public {
        vm.prank(owner);
        token.setBlacklist(alice, true);

        vm.prank(alice);
        vm.expectRevert(MeowelotToken.Blacklisted.selector);
        token.requestToken();
    }

    function test_RequestToken_WhenPausedReverts() public {
        vm.prank(owner);
        token.pause();

        vm.prank(alice);
        vm.expectRevert();
        token.requestToken();
    }

    // ─── mint ─────────────────────────────────────────────────────────────────
    function test_Mint_OwnerCanMint() public {
        uint256 amount = 100_000 * 1e18;
        vm.prank(owner);
        token.mint(alice, amount);

        assertEq(token.balanceOf(alice), amount);
    }

    function test_Mint_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit MeowelotToken.Minted(alice, 1000 * 1e18);
        vm.prank(owner);
        token.mint(alice, 1000 * 1e18);
    }

    function test_Mint_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        token.mint(alice, 1000 * 1e18);
    }

    function test_Mint_ExceedsMaxSupplyReverts() public {
        // Owner already has 5M, try to mint 5M+1
        vm.prank(owner);
        vm.expectRevert(MeowelotToken.ExceedsMaxSupply.selector);
        token.mint(alice, 5_000_001 * 1e18);
    }

    function test_Mint_ExactlyToMaxSupply() public {
        uint256 remaining = MAX_SUPPLY - token.totalSupply();
        vm.prank(owner);
        token.mint(alice, remaining);
        assertEq(token.totalSupply(), MAX_SUPPLY);
    }

    function test_Mint_ZeroAddressReverts() public {
        vm.prank(owner);
        vm.expectRevert(MeowelotToken.ZeroAddress.selector);
        token.mint(address(0), 1000 * 1e18);
    }

    function test_Mint_WhenPausedReverts() public {
        vm.prank(owner);
        token.pause();

        vm.prank(owner);
        vm.expectRevert();
        token.mint(alice, 1000 * 1e18);
    }

    // ─── Transfer fees ────────────────────────────────────────────────────────
    function test_Transfer_FeesApplied() public {
        uint256 amount = 10_000 * 1e18;
        vm.prank(owner);
        token.transfer(alice, amount + 50_000 * 1e18); // give alice extra

        uint256 aliceBalBefore = token.balanceOf(alice);
        uint256 treasuryBefore = token.balanceOf(treasury);
        uint256 supplyBefore   = token.totalSupply();

        vm.prank(alice);
        token.transfer(bob, amount);

        uint256 burnAmt     = amount * 100 / 10_000; // 1%
        uint256 treasuryAmt = amount * 50  / 10_000; // 0.5%
        uint256 extraBurn   = amount * 50  / 10_000; // 0.5%
        uint256 netAmt      = amount - burnAmt - treasuryAmt - extraBurn;

        assertEq(token.balanceOf(bob), netAmt);
        assertEq(token.balanceOf(treasury), treasuryBefore + treasuryAmt);
        assertEq(token.totalSupply(), supplyBefore - burnAmt - extraBurn);
        assertEq(token.balanceOf(alice), aliceBalBefore - amount);
    }

    function test_Transfer_OwnerSkipsFees() public {
        // Owner transfers should not trigger fees
        uint256 amount = 1_000 * 1e18;
        uint256 supplyBefore = token.totalSupply();

        vm.prank(owner);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), supplyBefore); // no burn
    }

    function test_Transfer_AntiWhalePreventsOverCap() public {
        // Give bob just under the cap
        vm.prank(owner);
        token.transfer(bob, ANTI_WHALE_CAP - 500 * 1e18);

        // Give alice some to send
        vm.prank(owner);
        token.transfer(alice, 50_000 * 1e18);

        // Sending 1000 tokens to bob should exceed cap after fees
        vm.prank(alice);
        vm.expectRevert(MeowelotToken.ExceedsAntiWhaleCap.selector);
        token.transfer(bob, 1_000 * 1e18);
    }

    // ─── NFT minting on large transfers ──────────────────────────────────────
    function test_Transfer_MintsNFTAboveThreshold() public {
        vm.prank(owner);
        token.transfer(alice, 50_000 * 1e18);

        uint256 nftsBefore = nft.balanceOf(bob);

        vm.prank(alice);
        token.transfer(bob, NFT_THRESHOLD + 1 * 1e18);

        assertEq(nft.balanceOf(bob), nftsBefore + 1);
    }

    function test_Transfer_NoNFTBelowThreshold() public {
        vm.prank(owner);
        token.transfer(alice, 50_000 * 1e18);

        vm.prank(alice);
        token.transfer(bob, NFT_THRESHOLD - 1 * 1e18);

        assertEq(nft.balanceOf(bob), 0);
    }

    // ─── totalBurned tracking ─────────────────────────────────────────────────
    function test_TotalBurnedIncrementsOnTransfer() public {
        uint256 amount = 5_000 * 1e18;
        vm.prank(owner);
        token.transfer(alice, 50_000 * 1e18);

        uint256 burnedBefore = token.totalBurned();

        vm.prank(alice);
        token.transfer(bob, amount);

        uint256 expectedBurn = amount * 150 / 10_000; // 1% + 0.5%
        assertEq(token.totalBurned(), burnedBefore + expectedBurn);
    }

    // ─── Admin functions ──────────────────────────────────────────────────────
    function test_SetTreasury() public {
        address newTreasury = address(0x99);
        vm.prank(owner);
        token.setTreasury(newTreasury);
        assertEq(token.treasuryAddress(), newTreasury);
    }

    function test_SetFees_TooHighReverts() public {
        vm.prank(owner);
        vm.expectRevert(MeowelotToken.TaxTooHigh.selector);
        token.setFees(500, 300, 300); // 11% total
    }

    function test_PauseUnpause() public {
        vm.prank(owner);
        token.pause();
        assertTrue(token.paused());

        vm.prank(owner);
        token.unpause();
        assertFalse(token.paused());
    }

    function test_RemainingMintable() public view {
        uint256 remaining = token.remainingMintable();
        assertEq(remaining, MAX_SUPPLY - token.totalSupply());
    }
}
