// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC173} from "./interfaces/IERC173.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {ITokenManager} from "./interfaces/ITokenManager.sol";
import {IStaffManager} from "./interfaces/IStaffManager.sol";
import {IStudentManager} from "./interfaces/IStudentManager.sol";
import {LibSafeERC20} from "./libraries/LibSafeERC20.sol";
import {LibSMS} from "./libraries/LibSMS.sol";

/**
 * @title SMS (School Management System)
 * @notice A contract that handles school management functionalities, including:
 * - Student and staff registration
 * - School fees payment on registration using supported ERC20 tokens where pricing is based on grade/levels from 100 - 400 level.
 * - Staff salary management with ERC20 token payments
 * - Payment status can be updated once payment is made which should include the timestamp
 * @dev This contract implements the ERC173 ownership standard for access control. The owner can manage staff and student records, set fee structures, and handle salary payments. The contract is designed to be extensible for future features such as course management and attendance tracking.
 */
contract SMS is IERC173, ITokenManager, IStaffManager, IStudentManager {
    uint8 public constant MAX_SUPPORTED_TOKENS = 10;

    address private _owner;
    uint256 private _status;
    LibSMS.SupportedToken[] private _supportedTokens;
    mapping(uint256 => LibSMS.Student) private _students;
    mapping(address => LibSMS.Staff) private _staff;
    mapping(uint256 => LibSMS.StudentPaymentCode) private _paymentCodes;

    error TokenNotFound(address tokenAddress);

    modifier nonReentrant() {
        require(_status == 0, "ReentrancyGuard: reentrant call");
        _status = 1;
        _;
        _status = 0;
    }

    constructor() {
        _owner = msg.sender;
        _status = 0;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "SMS: caller is not the owner");
        _;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external override onlyOwner {
        require(_newOwner != address(0), "SMS: new owner is the zero address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

    function addSupportedToken(
        address _tokenAddress,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) external override onlyOwner {
        require(
            _supportedTokens.length < MAX_SUPPORTED_TOKENS,
            "SMS: max supported tokens reached"
        );
        require(_tokenAddress != address(0), "SMS: token address is zero");
        require(
            !isTokenSupported(_tokenAddress),
            "SMS: token already supported"
        );
        _supportedTokens.push(
            LibSMS.SupportedToken({
                tokenAddress: _tokenAddress,
                tokenSymbol: _tokenSymbol,
                tokenDecimals: _tokenDecimals,
                supportedAt: uint40(block.timestamp)
            })
        );
        emit TokenSupported(_tokenAddress, _tokenSymbol, _tokenDecimals);
    }

    function removeSupportedToken(
        address _tokenAddress
    ) external override onlyOwner {
        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            if (_supportedTokens[i].tokenAddress == _tokenAddress) {
                _supportedTokens[i] = _supportedTokens[
                    _supportedTokens.length - 1
                ];
                _supportedTokens.pop();
                emit TokenRemoved(_tokenAddress);
                return;
            }
        }
        revert TokenNotFound(_tokenAddress);
    }

    function isTokenSupported(
        address _tokenAddress
    ) public view override returns (bool) {
        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            if (_supportedTokens[i].tokenAddress == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    function getSupportedTokens()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory tokenAddresses = new address[](
            _supportedTokens.length
        );
        for (uint8 i = 0; i < _supportedTokens.length; i++) {
            tokenAddresses[i] = _supportedTokens[i].tokenAddress;
        }
        return tokenAddresses;
    }

    function addStaff(
        address _staffAddress,
        string memory _name,
        string memory _position,
        uint256 _salary,
        address _salaryToken
    ) external override onlyOwner {
        require(
            _staffAddress != address(0),
            "SMS: staff address cannot be zero"
        );
        require(
            !_staff[_staffAddress].isActive,
            "SMS: staff already exists"
        );
        require(
            isTokenSupported(_salaryToken),
            "SMS: salary token not supported"
        );

        LibSMS.Staff storage staff = _staff[_staffAddress];
        staff.id = uint256(
            keccak256(abi.encodePacked(_staffAddress, block.timestamp))
        );
        staff.name = _name;
        staff.position = _position;
        staff.salary = _salary;
        staff.salaryToken = _salaryToken;
        staff.wallet = payable(_staffAddress);
        staff.isActive = true;
        staff.createdAt = uint40(block.timestamp);

        emit StaffAdded(_staffAddress, _name, _position);
    }

    function removeStaff(address _staffAddress) external override onlyOwner {
        require(_staff[_staffAddress].isActive, "SMS: staff not found");
        _staff[_staffAddress].isActive = false;
        emit StaffRemoved(_staffAddress);
    }

    function updateSalary(
        address _staffAddress,
        uint256 _newSalary,
        address _tokenAddress
    ) external override onlyOwner {
        require(_staff[_staffAddress].isActive, "SMS: staff not found");
        require(
            isTokenSupported(_tokenAddress),
            "SMS: salary token not supported"
        );

        LibSMS.Staff storage staff = _staff[_staffAddress];
        staff.salary = _newSalary;
        staff.salaryToken = _tokenAddress;
        staff.modifiedAt = uint40(block.timestamp);

        emit SalaryUpdated(_staffAddress, _newSalary, _tokenAddress);
    }

    function getStaffDetails(
        address _staffAddress
    )
        external
        view
        override
        returns (
            string memory name,
            string memory position,
            uint256 salary,
            address salaryToken
        )
    {
        require(_staff[_staffAddress].isActive, "SMS: staff not found");
        LibSMS.Staff memory staff = _staff[_staffAddress];
        return (staff.name, staff.position, staff.salary, staff.salaryToken);
    }

    function paySalary(address _staffAddress) external override onlyOwner nonReentrant returns (bool) {
        require(_staff[_staffAddress].isActive, "SMS: staff not found");
        LibSMS.Staff storage staff = _staff[_staffAddress];
        require(
            isTokenSupported(staff.salaryToken),
            "SMS: salary token not supported"
        );

        // Make payment
        LibSafeERC20.safeTransferFrom(
            IERC20(staff.salaryToken),
            msg.sender,
            staff.wallet,
            staff.salary
        );

        staff.salaryHistory.push(
            LibSMS.SalaryHistory({
                staff: _staffAddress,
                amount: staff.salary,
                tokenAddress: staff.salaryToken,
                paymentStatus: LibSMS.PaymentStatus.PAID,
                paidAt: uint40(block.timestamp)
            })
        );
        staff.paidAt = uint40(block.timestamp);
        emit SalaryUpdated(_staffAddress, staff.salary, staff.salaryToken);
        return true;
    }

    function addStudent(
        string memory _name,
        LibSMS.StudentLevel _level,
        string memory _department,
        string memory _email
    ) external override onlyOwner {
        require(bytes(_name).length > 0, "SMS: name cannot be empty");
        require(bytes(_department).length > 0, "SMS: department cannot be empty");
        require(bytes(_email).length > 0, "SMS: email cannot be empty");

        uint256 studentId = uint256(
            keccak256(abi.encodePacked(_name, _email, block.timestamp))
        );

        _students[studentId] = LibSMS.Student({
            id: studentId,
            name: _name,
            level: _level,
            department: _department,
            email: _email,
            paymentStatus: LibSMS.PaymentStatus.UNPAID,
            isActive: true,
            paidAt: 0,
            createdAt: uint40(block.timestamp),
            modifiedAt: uint40(block.timestamp)
        });
        emit StudentAdded(studentId, _name, _level, _department);

        // Generate a payment code that students can use to make payment
        uint16 paymentCode = uint16(uint256(keccak256(abi.encodePacked(studentId))) % 10000);
        _paymentCodes[studentId] = LibSMS.StudentPaymentCode({
            code: paymentCode,
            studentId: studentId,
            generatedAt: uint40(block.timestamp),
            isUsed: false
        });
        emit PaymentCodeGenerated(studentId, paymentCode);
    }

    function updateStudent(
        uint256 _studentId,
        string memory _name,
        LibSMS.StudentLevel _level,
        string memory _department,
        string memory _email
    ) external override onlyOwner {
        require(_students[_studentId].isActive, "SMS: student not found");
        require(bytes(_name).length > 0, "SMS: name cannot be empty");
        require(bytes(_department).length > 0, "SMS: department cannot be empty");
        require(bytes(_email).length > 0, "SMS: email cannot be empty");

        LibSMS.Student storage student = _students[_studentId];
        student.name = _name;
        student.level = _level;
        student.department = _department;
        student.email = _email;
        student.modifiedAt = uint40(block.timestamp);

        emit StudentDetailsUpdated(_studentId, _name, _level, _department);
    }

    function removeStudent(uint256 _studentId) external override onlyOwner {
        require(_students[_studentId].isActive, "SMS: student not found");
        _students[_studentId].isActive = false;
        emit StudentRemoved(_studentId);
    }

    function makePayment(uint256 _studentId, uint16 _code, uint256 _amount, address _tokenAddress) external override nonReentrant returns (bool) {
        require(_students[_studentId].isActive, "SMS: student not found");
        require(
            isTokenSupported(_tokenAddress),
            "SMS: token not supported"
        );
        require(
            _students[_studentId].paymentStatus == LibSMS.PaymentStatus.UNPAID,
            "SMS: payment already made"
        );
        require(
            _paymentCodes[_studentId].code == _code,
            "SMS: invalid payment code"
        );
        require(!_paymentCodes[_studentId].isUsed, "SMS: payment code already used");

        // Mark the payment code as used
        _paymentCodes[_studentId].isUsed = true;

        LibSMS.Student storage student = _students[_studentId];

        // Make payment (assuming that someone is sending the payment on behalf of the student)
        LibSafeERC20.safeTransferFrom(
            IERC20(_tokenAddress),
            msg.sender,
            address(this),
            _amount
        );

        student.paymentStatus = LibSMS.PaymentStatus.PAID;
        student.paidAt = uint40(block.timestamp);
        student.modifiedAt = uint40(block.timestamp);

        emit StudentPaymentStatusUpdated(_studentId, LibSMS.PaymentStatus.PAID, student.paidAt);
        return true;
    }

    function getStudentDetails(
        uint256 _studentId
    ) external view override returns (LibSMS.Student memory) {
        require(_students[_studentId].isActive, "SMS: student not found");
        return _students[_studentId];
    }
}
