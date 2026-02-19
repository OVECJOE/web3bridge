// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {LibSMS} from "../libraries/LibSMS.sol";

interface IStudentManager {
    event StudentAdded(
        bytes32 indexed studentId,
        string name,
        LibSMS.StudentLevel level,
        string department
    );
    event StudentDetailsUpdated(
        bytes32 indexed studentId,
        string name,
        LibSMS.StudentLevel level,
        string department
    );
    event StudentRemoved(bytes32 indexed studentId);
    event StudentPaymentStatusUpdated(
        bytes32 indexed studentId,
        LibSMS.PaymentStatus paymentStatus,
        uint40 paidAt
    );

    function addStudent(
        string memory _name,
        LibSMS.StudentLevel _level,
        string memory _department,
        string memory _email,
        uint256 _fee
    ) external returns (bytes32, uint16);
    function updateStudent(
        bytes32 _studentId,
        string memory _name,
        LibSMS.StudentLevel _level,
        string memory _department,
        string memory _email,
        uint256 _fee
    ) external;
    function removeStudent(bytes32 _studentId) external;
    function makePayment(
        bytes32 _studentId,
        uint16 _code,
        uint256 _amount,
        address _tokenAddress
    ) external returns (bool);
    function getStudentDetails(
        bytes32 _studentId
    ) external view returns (LibSMS.Student memory);
}
