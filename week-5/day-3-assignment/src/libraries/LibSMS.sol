// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title LibSMS
 * @notice A library for the School Management System (SMS) contract, providing utility functions and data structures to support the main SMS contract functionalities.
*/
library LibSMS {
    enum StudentLevel {
        LEVEL_100,
        LEVEL_200,
        LEVEL_300,
        LEVEL_400
    }

    enum PaymentStatus {
        UNPAID,
        PAID
    }

    struct SupportedToken {
        address tokenAddress;
        string tokenSymbol;
        uint8 tokenDecimals;
        uint40 supportedAt;
    }

    struct Student {
        uint256 id;
        string name;
        StudentLevel level;
        string department;
        string email;
        PaymentStatus paymentStatus;
        bool isActive;
        uint40 paidAt;
        uint40 createdAt;
        uint40 modifiedAt;
    }

    struct StudentPaymentCode {
        uint16 code;
        uint256 studentId;
        uint40 generatedAt;
        bool isUsed;
    }

    struct SalaryHistory {
        address staff;
        uint256 amount;
        address tokenAddress;
        PaymentStatus paymentStatus;
        uint40 paidAt;
    }

    struct Staff {
        uint256 id;
        string name;
        string position;
        string email;
        address payable wallet;
        uint256 salary; // Salary in smallest unit of the token (e.g., wei for ETH)
        address salaryToken; // Address of the ERC20 token used for salary payment
        SalaryHistory[] salaryHistory;
        bool isActive;
        uint40 paidAt;
        uint40 createdAt;
        uint40 modifiedAt;
    }
}
