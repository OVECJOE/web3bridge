// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MultiSigWallet is Initializable {
    // ===================== Enums =====================

    enum TransactionApprovalStatus {
        PENDING,
        APPROVED,
        REJECTED
    }

    // ===================== Structs =====================

    struct Transaction {
        address creator;
        address to;
        uint256 value;
        bytes data;
        TransactionApprovalStatus status;
        uint8 approvals;
        uint8 rejections;
        address[] approvers;
        address[] rejectors;
        bool executed;
        uint40 executedAt;
        uint40 createdAt;
    }

    struct Deposit {
        bytes32 txHash;
        address creator;
        uint256 amount;
        uint40 createdAt;
    }

    // ===================== Constants =====================

    uint256 private constant MAX_OWNERS = 5;

    // ===================== State Variables =====================

    address[] private _owners;
    uint256 private _threshold;
    uint256 private _nonce;

    mapping(address => bool) private _isOwner;

    Transaction[] private _transactions;
    mapping(uint256 => uint256) private _txIndexes;
    uint256 private _transactionCount;

    mapping(uint256 => mapping(address => bool)) private _approvers;
    mapping(uint256 => mapping(address => bool)) private _rejectors;

    mapping(address => Deposit) private _deposits;

    // ===================== Events =====================

    event Initialized(address[] owners, uint256 threshold);

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    event TransactionSubmitted(
        address indexed sender,
        uint256 transactionId,
        uint40 createdAt
    );
    event TransactionSigned(address indexed signer, uint256 transactionId);
    event TransactionUnsigned(address indexed signer, uint256 transactionId);
    event TransactionApproved(address indexed approver, uint256 transactionId);
    event TransactionIndividuallyRejected(
        address indexed rejector,
        uint256 transactionId
    );
    event TransactionRejected(address indexed rejector, uint256 transactionId);
    event TransactionExecuted(uint256 transactionId);

    event DepositMade(address indexed owner, uint256 amount);

    // ======================= Custom Errors =========================

    error NotContractOwner();
    error NotOwner();
    error AlreadyOwner();
    error InvalidTransaction();
    error AlreadyExecuted();
    error NotPendingTransaction();
    error AlreadyApproved();
    error AlreadyRejected();
    error NotApprover();
    error NotRejector();
    error InvalidOwner();
    error AtLeastOneOwner();
    error MaxOwnersCountReached();
    error BadThreshold();
    error InvalidParam();
    error OperationUnauthorized();
    error InvalidAddress();

    // ======================= Modifiers =======================

    modifier onlyContractOwner() {
        require(msg.sender == _owners[0], NotContractOwner());
        _;
    }

    modifier onlyOwner() {
        require(_isOwner[msg.sender], NotOwner());
        _;
    }

    modifier txExists(uint256 _txId) {
        uint256 _txIndex = _txIndexes[_txId];
        require(_txIndex < _transactions.length, InvalidTransaction());
        _;
    }

    modifier notExecuted(uint256 _txId) {
        uint256 _txIndex = _txIndexes[_txId];
        require(!_transactions[_txIndex].executed, AlreadyExecuted());
        _;
    }

    modifier onlyPendingTransaction(uint256 _txId) {
        uint256 _txIndex = _txIndexes[_txId];
        require(
            _transactions[_txIndex].status == TransactionApprovalStatus.PENDING,
            NotPendingTransaction()
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ===================== Internal Functions =====================

    function _addApprover(uint256 _txId, address _approver) internal {
        uint256 _txIndex = _txIndexes[_txId];
        require(!_approvers[_txId][_approver], AlreadyApproved());
        _approvers[_txId][_approver] = true;
        _transactions[_txIndex].approvals++;
    }

    function _removeApprover(uint256 _txId, address _approver) internal {
        uint256 _txIndex = _txIndexes[_txId];
        require(_approvers[_txId][_approver], NotApprover());
        _approvers[_txId][_approver] = false;
        _transactions[_txIndex].approvals--;
    }

    function _addRejector(uint256 _txId, address _rejector) internal {
        uint256 _txIndex = _txIndexes[_txId];
        require(!_rejectors[_txId][_rejector], AlreadyRejected());
        _rejectors[_txId][_rejector] = true;
        _transactions[_txIndex].rejections++;
    }

    function _removeRejector(uint256 _txId, address _rejector) internal {
        uint256 _txIndex = _txIndexes[_txId];
        require(_rejectors[_txId][_rejector], NotRejector());
        _rejectors[_txId][_rejector] = false;
        _transactions[_txIndex].rejections--;
    }

    function _hasReachedLimit(
        uint256 _txId
    ) internal view txExists(_txId) returns (bool) {
        uint256 _txIndex = _txIndexes[_txId];
        return
            _transactions[_txIndex].approvals >= 2 ||
            _transactions[_txIndex].rejections >= 2;
    }

    // ===================== Public Functions =====================

    function getTxCount() external view returns (uint256) {
        return _transactionCount;
    }

    function getOwnersCount() external view returns (uint256) {
        return _owners.length;
    }

    function getOwners() external view onlyOwner returns (address[] memory) {
        return _owners;
    }

    function getOwner(
        uint256 _index
    ) external view onlyOwner returns (address) {
        require(_index < _owners.length, InvalidParam());
        return _owners[_index];
    }

    function getTransaction(
        uint256 _txId
    ) external view onlyOwner txExists(_txId) returns (Transaction memory) {
        uint256 _txIndex = _txIndexes[_txId];
        return _transactions[_txIndex];
    }

    function getWalletBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function getDeposit(
        address _owner
    ) external view onlyOwner returns (Deposit memory) {
        return _deposits[_owner];
    }

    function getDepositAmount(
        address _owner
    ) external view onlyOwner returns (uint256) {
        return _deposits[_owner].amount;
    }

    function getTotalDeposits() external view onlyOwner returns (uint256) {
        uint256 totalDeposits = 0;
        for (uint256 i = 0; i < _owners.length; i++) {
            totalDeposits += _deposits[_owners[i]].amount;
        }
        return totalDeposits;
    }

    function initialize(
        address[] calldata _signers,
        uint256 _requiredConfirmations
    ) external initializer {
        require(_signers.length >= 1, AtLeastOneOwner());
        require(
            _requiredConfirmations >= 1 &&
                _requiredConfirmations <= _signers.length,
            BadThreshold()
        );

        for (uint256 i = 0; i < _signers.length; ) {
            address owner = _signers[i];

            require(owner != address(0), InvalidOwner());
            require(!_isOwner[owner], AlreadyOwner());

            _isOwner[owner] = true;
            _owners.push(owner);

            emit OwnerAdded(owner);

            unchecked {
                i++;
            }
        }

        _threshold = _requiredConfirmations;
        emit Initialized(_owners, _requiredConfirmations);
    }

    function addOwner(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0), InvalidOwner());
        require(!_isOwner[_newOwner], AlreadyOwner());
        require(_owners.length < MAX_OWNERS, MaxOwnersCountReached());

        _isOwner[_newOwner] = true;
        _owners.push(_newOwner);
        emit OwnerAdded(_newOwner);
    }

    function removeOwner(address _owner) external onlyContractOwner {
        require(_owner != address(0), InvalidOwner());
        require(_isOwner[_owner], NotOwner());
        require(_owners.length > 1, AtLeastOneOwner());

        for (uint8 i = 0; i < _owners.length; i++) {
            if (_owners[i] == _owner) {
                require(i != 0, OperationUnauthorized());
                _owners[i] = _owners[_owners.length - 1];
                _owners.pop();

                _isOwner[_owner] = false;
                emit OwnerRemoved(_owner);
                break;
            }
        }
    }

    function replaceOwner(
        address _oldOwner,
        address _newOwner
    ) external onlyContractOwner {
        require(_oldOwner != address(0), InvalidOwner());
        require(_newOwner != address(0), InvalidOwner());
        require(_oldOwner != _newOwner, InvalidParam());
        require(_isOwner[_oldOwner], NotOwner());
        require(!_isOwner[_newOwner], AlreadyOwner());

        for (uint8 i = 0; i < _owners.length; i++) {
            if (_owners[i] == _oldOwner) {
                _owners[i] = _newOwner;
                emit OwnerRemoved(_oldOwner);
                emit OwnerAdded(_newOwner);
                break;
            }
        }
    }

    function initiateTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner {
        require(_to != address(0), InvalidAddress());

        uint256 txId = _transactionCount++;
        uint40 createdAt = uint40(block.timestamp);

        _transactions.push(
            Transaction({
                creator: msg.sender,
                to: _to,
                value: _value,
                data: _data,
                status: TransactionApprovalStatus.PENDING,
                approvals: 0,
                rejections: 0,
                approvers: new address[](MAX_OWNERS),
                rejectors: new address[](MAX_OWNERS),
                executed: false,
                executedAt: uint40(0),
                createdAt: createdAt
            })
        );
        _txIndexes[txId] = _transactions.length - 1;

        emit TransactionSubmitted(msg.sender, txId, createdAt);
    }

    function signTransaction(
        uint256 _txId
    ) external onlyOwner onlyPendingTransaction(_txId) {
        uint256 _txIndex = _txIndexes[_txId];
        require(
            msg.sender != _transactions[_txIndex].creator,
            OperationUnauthorized()
        );

        uint256 approvalCount = _transactions[_txIndex].approvals;
        require(approvalCount < _threshold, OperationUnauthorized());

        _approvers[_txId][msg.sender] = true;
        _transactions[_txIndex].approvals++;
        _transactions[_txIndex].approvers[approvalCount] = msg.sender;

        if (_transactions[_txIndex].approvals >= _threshold) {
            _transactions[_txIndex].status = TransactionApprovalStatus.APPROVED;
            emit TransactionApproved(msg.sender, _txId);
        }

        emit TransactionSigned(msg.sender, _txId);
    }

    function unsignTransaction(
        uint256 _txId
    ) external onlyOwner onlyPendingTransaction(_txId) {
        uint256 _txIndex = _txIndexes[_txId];
        require(
            msg.sender != _transactions[_txIndex].creator,
            OperationUnauthorized()
        );

        uint256 approvalCount = _transactions[_txIndex].approvals;
        require(approvalCount < _threshold, OperationUnauthorized());

        _removeApprover(_txId, msg.sender);
        _transactions[_txIndex].approvers[approvalCount - 1] = address(0);

        emit TransactionUnsigned(msg.sender, _txId);
    }

    function rejectTransaction(
        uint256 _txId
    ) external onlyOwner onlyPendingTransaction(_txId) {
        uint256 _txIndex = _txIndexes[_txId];
        require(
            msg.sender != _transactions[_txIndex].creator,
            OperationUnauthorized()
        );

        uint256 rejectionCount = _transactions[_txIndex].rejections;
        require(rejectionCount < _threshold, OperationUnauthorized());

        _rejectors[_txId][msg.sender] = true;
        _transactions[_txIndex].rejections++;
        _transactions[_txIndex].rejectors[rejectionCount] = msg.sender;

        if (_transactions[_txIndex].rejections >= _threshold) {
            _transactions[_txIndex].status = TransactionApprovalStatus.REJECTED;
            emit TransactionRejected(msg.sender, _txId);
        }

        emit TransactionIndividuallyRejected(msg.sender, _txId);
    }

    function deposit() external payable onlyOwner {
        require(msg.value > 0, "Invalid amount");

        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        require(success, "Deposit failed");

        _deposits[msg.sender] = Deposit({
            txHash: keccak256(
                abi.encode(msg.sender, msg.value, block.timestamp)
            ),
            creator: msg.sender,
            amount: msg.value,
            createdAt: uint40(block.timestamp)
        });

        emit DepositMade(msg.sender, msg.value);
    }

    function execute(uint256 _transactionId) external onlyOwner {
        require(_transactionId < _transactionCount, "Invalid transaction id");

        Transaction storage _tx = _transactions[_transactionId];

        require(msg.sender == _tx.creator, "Not the transaction owner");
        require(
            _tx.status == TransactionApprovalStatus.APPROVED,
            "Transaction not approved"
        );
        require(!_tx.executed, "Transaction already executed");

        (bool success, ) = payable(_tx.to).call{value: _tx.value}(_tx.data);
        require(success, "Transaction failed");

        _tx.executed = true;
        _tx.executedAt = uint40(block.timestamp);

        emit TransactionExecuted(_transactionId);
    }

    receive() external payable {}

    fallback() external payable {}
}
