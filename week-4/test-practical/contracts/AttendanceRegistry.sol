// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.30;

contract AttendanceRegistry {
    struct Student {
        string name;
        uint8 age;
        bool present;
    }

    Student[] public students;
    mapping(bytes32 => uint256) private _nameToIndex;
    mapping(bytes32 => bool) private _exists;

    event StudentAdded(string name, uint8 age, bool present);
    event AttendanceMarked(string name, bool present);

    function addStudent(string calldata _name, uint8 _age) external returns (Student memory) {
        bytes32 nameHash = keccak256(bytes(_name));

        if (_exists[nameHash]) {
            uint256 idx = _nameToIndex[nameHash];
            bool newPresent = !students[idx].present;
            students[idx].present = newPresent;
            emit AttendanceMarked(_name, newPresent);
            return students[idx];
        }

        _nameToIndex[nameHash] = students.length;
        _exists[nameHash] = true;
        students.push(Student(_name, _age, true));
        emit StudentAdded(_name, _age, true);
        return students[students.length - 1];
    }
}
