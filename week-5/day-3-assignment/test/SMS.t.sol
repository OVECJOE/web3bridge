// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, Vm} from "forge-std/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {LibSMS} from "../src/libraries/LibSMS.sol";
import {SMS} from "../src/SMS.sol";

contract SMSTest is Test {
    MockERC20 token;
    SMS sms;

    address owner;
    address alice; // parent
    address bob; // staff

    event StudentAdded(
        bytes32 indexed studentId,
        string name,
        LibSMS.StudentLevel level,
        string department
    );

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

    function testAddStudentWorks() public {
        (bytes32 studentId,) = sms.addStudent(
            "Levi Harrison",
            LibSMS.StudentLevel.LEVEL_100,
            "Computer Science",
            "levi.harrison@example.com",
            500e18
        );
        LibSMS.Student memory student = sms.getStudentDetails(studentId);
        assertEq(student.name, "Levi Harrison");
        assertTrue(student.level == LibSMS.StudentLevel.LEVEL_100);
        assertEq(student.department, "Computer Science");
    }

    function testAddStudentEmitsStudentAddedEvent() public {
        vm.expectEmit(false, false, false, false);
        emit StudentAdded(
            0x0,
            "Levi Harrison",
            LibSMS.StudentLevel.LEVEL_100,
            "Computer Science"
        );

        sms.addStudent(
            "Levi Harrison",
            LibSMS.StudentLevel.LEVEL_100,
            "Computer Science",
            "levi.harrison@example.com",
            500e18
        );
    }

    function testMakePayment() public {
        (bytes32 studentId, uint16 paymentCode) = sms.addStudent(
            "Levi Harrison",
            LibSMS.StudentLevel.LEVEL_100,
            "Computer Science",
            "levi.harrison@example.com",
            500e18
        );
        
        
        vm.prank(alice);
        bool success = sms.makePayment(studentId, paymentCode, 500e18, address(token));
        assertTrue(success);
    }
}
