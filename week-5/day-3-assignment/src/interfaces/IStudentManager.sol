// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {LibSMS} from "../libraries/LibSMS.sol";

interface IStudentManager {
    event StudentAdded(
        uint256 indexed studentId,
        string name,
        uint8 level,
        string department
    );
    event StudentDetailsUpdated(
        uint256 indexed studentId,
        string name,
        uint8 level,
        string department
    );
    event StudentRemoved(uint256 indexed studentId);
    event StudentPaymentStatusUpdated(uint256 indexed studentId, LibSMS.PaymentStatus paymentStatus, uint40 paidAt);
    event PaymentCodeGenerated(uint256 indexed studentId, uint16 paymentCode);

    function addStudent(
        string memory _name,
        LibSMS.StudentLevel _level,
        string memory _department,
        string memory _email
    ) external;
    function updateStudent(
        uint256 _studentId,
        string memory _name,
        LibSMS.StudentLevel _level,
        string memory _department,
        string memory _email
    ) external;
    function removeStudent(uint256 _studentId) external;
    function makePayment(uint256 _studentId, uint16 _code, uint256 _amount, address _tokenAddress) external returns (bool);
    function getStudentDetails(
        uint256 _studentId
    ) external view returns (LibSMS.Student memory);
}
