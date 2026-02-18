// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TwoBottles} from "../src/2bottles.sol";

contract TwoBottlesTest is Test {
    TwoBottles public twoBottles;

    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    uint256 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10 ** DECIMALS;
    uint256 public constant TRANSFER_FEE_BPS = 200; // 2%
    uint256 public constant BASIS_POINTS = 10000;

    function setUp() public {
        // Set up accounts
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // Fund accounts with ETH for gas
        vm.deal(alice, 100 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);

        // Deploy contract
        twoBottles = new TwoBottles();
    }

    // ============================================
    // Events
    // ============================================

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event TransferFeeCollected(address indexed from, uint256 feeAmount);

    // ============================================
    // ERC20 Basic View Functions Tests
    // ============================================

    function testOwnerIsDeployerAndHasInitialBalance() public view {
        assertEq(twoBottles.owner(), owner, "Owner should be the deployer");
        assertEq(twoBottles.balanceOf(owner), twoBottles.totalSupply(), "Owner should have entire initial supply");
    }

    function testInitialSupply() public view {
        uint256 expectedSupply = INITIAL_SUPPLY;
        assertEq(twoBottles.totalSupply(), expectedSupply, "Initial supply should be 1 million tokens with 18 decimals");
    }

    function testNameAndSymbol() public view {
        assertEq(twoBottles.name(), "2Bottles", "Token name should be 2Bottles");
        assertEq(twoBottles.symbol(), "2BTL", "Token symbol should be 2BTL");
    }

    function testDecimals() public view {
        assertEq(twoBottles.decimals(), 18, "Decimals should be 18");
    }

    function testTotalSupplyConstant() public view {
        assertEq(twoBottles.totalSupply(), INITIAL_SUPPLY, "Total supply should equal initial supply");
    }

    // ============================================
    // BalanceOf Tests
    // ============================================

    function testBalanceOfOwner() public view {
        assertEq(twoBottles.balanceOf(owner), INITIAL_SUPPLY, "Owner should have entire supply");
    }

    function testBalanceOfZeroAddress() public view {
        assertEq(twoBottles.balanceOf(address(0)), 0, "Zero address should have 0 balance");
    }

    function testBalanceOfNewAddress() public view {
        assertEq(twoBottles.balanceOf(alice), 0, "New address should have 0 balance");
    }

    // ============================================
    // Transfer Tests
    // ============================================

    function testTransfer() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        // Give alice some tokens
        vm.prank(owner);
        twoBottles.transfer(alice, amount);
        
        assertEq(twoBottles.balanceOf(alice), amount - (amount * TRANSFER_FEE_BPS / BASIS_POINTS), "Alice should receive amount minus fee");
    }

    function testTransferWithFee() public {
        uint256 amount = 10 * 10 ** DECIMALS;
        uint256 expectedFee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        uint256 expectedReceived = amount - expectedFee;

        vm.prank(owner);
        twoBottles.transfer(alice, amount);

        assertEq(twoBottles.balanceOf(alice), expectedReceived, "Alice should receive amount minus fee");
        assertEq(twoBottles.balanceOf(address(twoBottles)), expectedFee, "Contract should receive the fee");
    }

    function testTransferToZeroAddress() public {
        uint256 amount = 10 * 10 ** DECIMALS;
        vm.prank(owner);
        vm.expectRevert("Address cannot be zero");
        twoBottles.transfer(address(0), amount);
    }

    function testTransferInsufficientBalance() public {
        uint256 amount = INITIAL_SUPPLY + 1;
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        twoBottles.transfer(bob, amount);
    }

    function testTransferToSelf() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        uint256 balanceBefore = twoBottles.balanceOf(owner);
        
        vm.prank(owner);
        vm.expectRevert("Cannot transfer to self");
        twoBottles.transfer(owner, amount);
        
        assertEq(twoBottles.balanceOf(owner), balanceBefore, "Balance should remain unchanged");
    }

    function testTransferZeroAmount() public {
        uint256 balanceBefore = twoBottles.balanceOf(alice);
        
        vm.prank(owner);
        twoBottles.transfer(alice, 0);
        
        assertEq(twoBottles.balanceOf(alice), balanceBefore, "Balance should remain unchanged");
    }

    function testMultipleTransfers() public {
        uint256 amount = 10 * 10 ** DECIMALS;
        
        // First transfer
        vm.prank(owner);
        twoBottles.transfer(alice, amount);
        uint256 aliceBalance = amount - (amount * TRANSFER_FEE_BPS / BASIS_POINTS);
        assertEq(twoBottles.balanceOf(alice), aliceBalance, "Alice balance after first transfer");
        
        // Second transfer from alice to bob
        vm.prank(alice);
        twoBottles.transfer(bob, aliceBalance);
        assertEq(twoBottles.balanceOf(bob), aliceBalance - (aliceBalance * TRANSFER_FEE_BPS / BASIS_POINTS), "Bob balance after second transfer");
    }

    // ============================================
    // Approve Tests
    // ============================================

    function testApprove() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        vm.prank(owner);
        twoBottles.approve(alice, amount);
        
        assertEq(twoBottles.allowance(owner, alice), amount, "Allowance should be set");
    }

    function testApproveToZeroAddress() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        vm.prank(owner);
        twoBottles.approve(address(0), amount);
        
        assertEq(twoBottles.allowance(owner, address(0)), amount, "Allowance to zero address should be set");
    }

    function testApproveUpdatesExistingAllowance() public {
        uint256 amount1 = 100 * 10 ** DECIMALS;
        uint256 amount2 = 200 * 10 ** DECIMALS;
        
        vm.prank(owner);
        twoBottles.approve(alice, amount1);
        assertEq(twoBottles.allowance(owner, alice), amount1);
        
        vm.prank(owner);
        twoBottles.approve(alice, amount2);
        assertEq(twoBottles.allowance(owner, alice), amount2, "Allowance should be updated");
    }

    function testApproveZeroValue() public {
        vm.prank(owner);
        twoBottles.approve(alice, 0);
        
        assertEq(twoBottles.allowance(owner, alice), 0, "Allowance should be 0");
    }

    // ============================================
    // TransferFrom Tests
    // ============================================

    function testTransferFrom() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        uint256 fee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        uint256 amountAfterFee = amount - fee;
        
        // Owner approves alice
        vm.prank(owner);
        twoBottles.approve(owner, amount);
        
        // Alice transfers from owner to bob
        vm.prank(alice);
        twoBottles.transferFrom(owner, bob, amount);
        
        assertEq(twoBottles.balanceOf(bob), amountAfterFee, "Bob should receive amount minus fee");
        assertEq(twoBottles.allowance(owner, alice), 0, "Allowance should be exhausted");
    }

    function testTransferFromInsufficientAllowance() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        vm.prank(owner);
        twoBottles.approve(alice, amount / 2);
        
        vm.prank(alice);
        vm.expectRevert("Insufficient allowance");
        twoBottles.transferFrom(owner, bob, amount);
    }

    function testTransferFromInsufficientBalance() public {
        uint256 amount = INITIAL_SUPPLY + 1;
        
        vm.prank(owner);
        twoBottles.approve(alice, amount);
        
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        twoBottles.transferFrom(owner, bob, amount);
    }

    function testTransferFromToZeroAddress() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        vm.prank(owner);
        twoBottles.approve(alice, amount);
        
        vm.prank(alice);
        vm.expectRevert("Address cannot be zero");
        twoBottles.transferFrom(owner, address(0), amount);
    }

    function testTransferFromPartialAllowance() public {
        uint256 approvedAmount = 100 * 10 ** DECIMALS;
        uint256 transferAmount = 30 * 10 ** DECIMALS;
        
        vm.prank(owner);
        twoBottles.approve(alice, approvedAmount);
        
        vm.prank(alice);
        twoBottles.transferFrom(owner, bob, transferAmount);
        
        assertEq(twoBottles.allowance(owner, alice), approvedAmount - transferAmount, "Remaining allowance should be correct");
    }

    // ============================================
    // Mint Tests
    // ============================================

    function testMint() public {
        uint256 mintAmount = 1000 * 10 ** DECIMALS;
        uint256 initialSupply = twoBottles.totalSupply();
        uint256 initialBalance = twoBottles.balanceOf(bob);
        
        twoBottles.mint(bob, mintAmount);
        
        assertEq(twoBottles.balanceOf(bob), initialBalance + mintAmount, "Recipient balance should increase");
        assertEq(twoBottles.totalSupply(), initialSupply + mintAmount, "Total supply should increase");
    }

    function testMintToZeroAddress() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        vm.expectRevert("Address cannot be zero");
        twoBottles.mint(address(0), amount);
    }

    function testMintByNonOwner() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        vm.prank(alice);
        vm.expectRevert("Only owner can call this function");
        twoBottles.mint(bob, amount);
    }

    function testMintZeroAmount() public {
        uint256 initialSupply = twoBottles.totalSupply();
        
        twoBottles.mint(bob, 0);
        
        assertEq(twoBottles.totalSupply(), initialSupply, "Total supply should remain unchanged");
    }

    function testMultipleMints() public {
        uint256 mintAmount = 100 * 10 ** DECIMALS;
        uint256 initialSupply = twoBottles.totalSupply();
        
        twoBottles.mint(alice, mintAmount);
        twoBottles.mint(bob, mintAmount);
        twoBottles.mint(charlie, mintAmount);
        
        assertEq(twoBottles.totalSupply(), initialSupply + (mintAmount * 3), "Total supply should increase by 3x mintAmount");
    }

    // ============================================
    // Burn Tests
    // ============================================

    function testBurn() public {
        uint256 burnAmount = 100 * 10 ** DECIMALS;
        uint256 initialSupply = twoBottles.totalSupply();
        uint256 initialBalance = twoBottles.balanceOf(owner);
        
        twoBottles.burn(burnAmount);
        
        assertEq(twoBottles.balanceOf(owner), initialBalance - burnAmount, "Balance should decrease");
        assertEq(twoBottles.totalSupply(), initialSupply - burnAmount, "Total supply should decrease");
    }

    function testBurnInsufficientBalance() public {
        uint256 burnAmount = twoBottles.balanceOf(alice) + 1;
        
        vm.prank(alice);
        vm.expectRevert("Insufficient balance to burn");
        twoBottles.burn(burnAmount);
    }

    function testBurnZeroAmount() public {
        uint256 initialSupply = twoBottles.totalSupply();
        
        twoBottles.burn(0);
        
        assertEq(twoBottles.totalSupply(), initialSupply, "Total supply should remain unchanged");
    }

    function testBurnAllSupply() public {
        uint256 balance = twoBottles.balanceOf(owner);
        
        twoBottles.burn(balance);
        
        assertEq(twoBottles.balanceOf(owner), 0, "Balance should be 0");
        assertEq(twoBottles.totalSupply(), 0, "Total supply should be 0");
    }

    // ============================================
    // Fee Calculation Tests
    // ============================================

    function testCalculateTransferFee() public view {
        uint256 amount = 1000 * 10 ** DECIMALS;
        uint256 expectedFee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        
        assertEq(twoBottles.calculateTransferFee(amount), expectedFee, "Fee calculation should be correct");
    }

    function testCalculateAmountAfterFee() public view {
        uint256 amount = 1000 * 10 ** DECIMALS;
        uint256 expectedFee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        uint256 expectedAfterFee = amount - expectedFee;
        
        assertEq(twoBottles.calculateAmountAfterFee(amount), expectedAfterFee, "Amount after fee should be correct");
    }

    function testFeeOnSmallAmount() public view {
        // Test rounding - 1 token with 2% fee = 0.02, should round to 0
        uint256 amount = 1 * 10 ** DECIMALS;
        uint256 expectedFee = 0; // Rounds down
        
        assertEq(twoBottles.calculateTransferFee(amount), expectedFee, "Small amount fee should round down");
    }

    function testFeeOnHundredTokens() public view {
        // 100 tokens = 100 * 10^18, 2% = 2 * 10^18
        uint256 amount = 100 * 10 ** DECIMALS;
        uint256 expectedFee = 2 * 10 ** DECIMALS;
        
        assertEq(twoBottles.calculateTransferFee(amount), expectedFee, "100 token fee should be exactly 2 tokens");
    }

    // ============================================
    // Fee Collection Tests
    // ============================================

    function testFeeCollectedInContract() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        uint256 expectedFee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        
        vm.prank(owner);
        twoBottles.transfer(alice, amount);
        
        assertEq(twoBottles.balanceOf(address(twoBottles)), expectedFee, "Fee should be collected in contract");
    }

    function testMultipleTransfersAccumulateFees() public {
        uint256 amount = 10 * 10 ** DECIMALS;
        uint256 expectedFee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        
        // Multiple transfers
        vm.prank(owner);
        twoBottles.transfer(alice, amount);
        
        vm.prank(owner);
        twoBottles.transfer(bob, amount);
        
        vm.prank(owner);
        twoBottles.transfer(charlie, amount);
        
        assertEq(twoBottles.balanceOf(address(twoBottles)), expectedFee * 3, "Fees should accumulate");
    }

    // ============================================
    // Event Tests
    // ============================================

    function testTransferEvent() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        uint256 amountAfterFee = amount - ((amount * TRANSFER_FEE_BPS) / BASIS_POINTS);
        
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, alice, amountAfterFee);
        twoBottles.transfer(alice, amount);
    }

    function testApprovalEvent() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, alice, amount);
        twoBottles.approve(alice, amount);
    }

    function testMintEvent() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), bob, amount);
        twoBottles.mint(bob, amount);
    }

    function testBurnEvent() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        
        // First give alice some tokens to burn
        vm.prank(owner);
        twoBottles.transfer(alice, amount);
        
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, address(0), amount);
        twoBottles.burn(amount);
    }

    function testTransferFeeCollectedEvent() public {
        uint256 amount = 100 * 10 ** DECIMALS;
        uint256 fee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit TransferFeeCollected(owner, fee);
        twoBottles.transfer(alice, amount);
    }

    // ============================================
    // Edge Cases and Boundary Tests
    // ============================================

    function testMaxUint256Transfer() public {
        // This would fail due to insufficient balance, which is expected
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        twoBottles.transfer(bob, type(uint256).max);
    }

    function testVerySmallTransfer() public {
        // Transfer 1 wei (smallest unit)
        uint256 amount = 1;
        
        // Fee would be 0 for 1 wei (2% of 1 = 0.02, rounds to 0)
        vm.prank(owner);
        twoBottles.transfer(alice, amount);
        
        // Alice should receive the full amount since fee rounds to 0
        assertEq(twoBottles.balanceOf(alice), 1, "Should receive 1 wei with 0 fee");
    }

    function testOwnerCanTransferAfterMinting() public {
        uint256 mintAmount = 1000 * 10 ** DECIMALS;
        uint256 transferAmount = 500 * 10 ** DECIMALS;
        
        // Mint to alice
        twoBottles.mint(alice, mintAmount);
        
        // Owner transfers
        vm.prank(owner);
        twoBottles.transfer(bob, transferAmount);
        
        assertEq(twoBottles.balanceOf(bob), transferAmount - ((transferAmount * TRANSFER_FEE_BPS) / BASIS_POINTS), "Transfer with fee works");
    }

    // ============================================
    // State Transition Tests
    // ============================================

    function testCompleteTokenLifecycle() public {
        // 1. Initial state
        assertEq(twoBottles.totalSupply(), INITIAL_SUPPLY);
        assertEq(twoBottles.balanceOf(owner), INITIAL_SUPPLY);
        
        // 2. Mint new tokens
        uint256 mintAmount = 1000 * 10 ** DECIMALS;
        twoBottles.mint(alice, mintAmount);
        assertEq(twoBottles.totalSupply(), INITIAL_SUPPLY + mintAmount);
        
        // 3. Owner approves alice
        uint256 approveAmount = 500 * 10 ** DECIMALS;
        vm.prank(owner);
        twoBottles.approve(alice, approveAmount);
        
        // 4. Alice transfers from owner to bob
        uint256 transferAmount = 300 * 10 ** DECIMALS;
        uint256 fee = (transferAmount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        vm.prank(alice);
        twoBottles.transferFrom(owner, bob, transferAmount);
        
        // 5. Verify final state
        assertEq(twoBottles.allowance(owner, alice), approveAmount - transferAmount);
        assertEq(twoBottles.balanceOf(bob), transferAmount - fee);
        
        // 6. Bob burns his tokens
        uint256 bobBalance = twoBottles.balanceOf(bob);
        vm.prank(bob);
        twoBottles.burn(bobBalance);
        
        // 7. Verify burn state
        assertEq(twoBottles.balanceOf(bob), 0);
        assertEq(twoBottles.totalSupply(), INITIAL_SUPPLY + mintAmount - bobBalance);
    }

    // ============================================
    // Fuzz Tests (Using Foundry's fuzzing)
    // ============================================

    function testFuzzTransfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= twoBottles.balanceOf(owner));
        
        uint256 fee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        uint256 amountAfterFee = amount - fee;
        
        vm.prank(owner);
        twoBottles.transfer(alice, amount);
        
        assertEq(twoBottles.balanceOf(alice), amountAfterFee, "Fuzz: Alice balance should match amount after fee");
    }

    function testFuzzApprove(uint256 amount) public {
        vm.assume(amount > 0);
        
        vm.prank(owner);
        twoBottles.approve(alice, amount);
        
        assertEq(twoBottles.allowance(owner, alice), amount, "Fuzz: Allowance should match approved amount");
    }

    function testFuzzMint(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint256).max / 2);
        
        uint256 initialSupply = twoBottles.totalSupply();
        
        twoBottles.mint(bob, amount);
        
        assertEq(twoBottles.balanceOf(bob), amount, "Fuzz: Minted amount should match");
        assertEq(twoBottles.totalSupply(), initialSupply + amount, "Fuzz: Total supply should increase");
    }

    function testFuzzBurn(uint256 amount) public {
        // First give alice a large balance
        uint256 mintAmount = 10000 * 10 ** DECIMALS;
        twoBottles.mint(alice, mintAmount);
        
        vm.assume(amount > 0 && amount <= mintAmount);
        
        uint256 initialSupply = twoBottles.totalSupply();
        
        vm.prank(alice);
        twoBottles.burn(amount);
        
        assertEq(twoBottles.balanceOf(alice), mintAmount - amount, "Fuzz: Balance should decrease");
        assertEq(twoBottles.totalSupply(), initialSupply - amount, "Fuzz: Total supply should decrease");
    }

    function testFuzzCalculateFee(uint256 amount) public view {
        uint256 expectedFee = (amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        
        assertEq(twoBottles.calculateTransferFee(amount), expectedFee, "Fuzz: Fee calculation should be consistent");
    }
}
