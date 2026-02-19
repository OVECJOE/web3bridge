// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../../contracts/AttendanceRegistry.sol";

contract AttendanceRegistryTest is Test {
    event StudentAdded(string name, uint8 age, bool present);
    event AttendanceMarked(string name, bool present);

    AttendanceRegistry registry;

    function setUp() public {
        registry = new AttendanceRegistry();
    }

    function testAddStudent() public {
        AttendanceRegistry.Student memory student = registry.addStudent("Alice", 20);
        assertEq(student.name, "Alice");
        assertEq(student.age, 20);
        assertEq(student.present, true);
    }

    function testAddStudentEmitForNewStudent() public {
        vm.expectEmit(true, true, true, true);
        emit StudentAdded("Alice", 20, true);
        registry.addStudent("Alice", 20);
    }

    function testAddStudentTogglePresence() public {
        AttendanceRegistry.Student memory student1 = registry.addStudent("Bob", 22);
        assertEq(student1.present, true);

        vm.expectEmit(true, true, true, true);
        emit AttendanceMarked("Bob", false);
        AttendanceRegistry.Student memory student2 = registry.addStudent("Bob", 22);
        assertEq(student2.present, false);
    }
}
