// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MultiSigWallet {
    enum TransactionApprovalStatus {
        PENDING,
        APPROVED,
        REJECTED
    }

    struct Transaction {
        address from;
        address to;
        uint256 value;
        bytes data;
        TransactionApprovalStatus status;
        uint8 approvals;
        address[] approvers;
        bool executed;
        uint40 executedAt;
        uint40 createdAt;
    }

    struct TransactionApprovals {
        uint8 count;
        address approver1;
        address approver2;
    }

    struct TransactionRejections {
        uint8 count;
        address rejector1;
        address rejector2;
    }

    struct Deposit {
        address owner;
        uint256 amount;
        uint40 createdAt;
    }

    address[] private _owners;
    mapping(uint256 => Transaction) private _transactions;
    uint256 private _transactionCount;
    mapping(uint256 => TransactionApprovals) private _approvals;
    mapping(uint256 => TransactionRejections) private _rejections;
    mapping(address => Deposit) private _deposits;

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event TransactionSubmitted(
        address indexed sender,
        uint256 transactionId,
        uint40 createdAt
    );
    event TransactionApproved(address indexed approver, uint256 transactionId);
    event TransactionRejected(address indexed rejector, uint256 transactionId);
    event TransactionExecuted(uint256 transactionId);
    event DepositMade(address indexed owner, uint256 amount);

    constructor(address[] memory owners) {
        require(
            owners.length >= 2 && owners.length <= 3,
            "At least 2 owners required"
        );
        _owners = owners;
        _transactionCount = 1;
    }

    modifier onlyOwner() {
        require(_isOwner(msg.sender), "Not an owner");
        _;
    }

    modifier onlyPendingTransaction(uint256 _transactionId) {
        require(_transactionId < _transactionCount, "Invalid transaction id");
        require(
            _transactions[_transactionId].status ==
                TransactionApprovalStatus.PENDING,
            "Transaction not pending"
        );
        _;
    }

    function _isOwner(address _owner) internal view returns (bool) {
        require(_owner != address(0), "Invalid owner");
        for (uint8 i = 0; i < _owners.length; i++) {
            if (_owners[i] == _owner) {
                return true;
            }
        }
        return false;
    }

    function _addApprover(uint256 _transactionId, address _approver) internal {
        if (_approvals[_transactionId].count == 0) {
            _approvals[_transactionId].approver1 = _approver;
        } else if (_approvals[_transactionId].count == 1) {
            require(
                _approvals[_transactionId].approver1 != _approver,
                "Already an approver"
            );
            _approvals[_transactionId].approver2 = _approver;
        }
    }

    function _addRejector(uint256 _transactionId, address _rejector) internal {
        if (_rejections[_transactionId].count == 0) {
            _rejections[_transactionId].rejector1 = _rejector;
        } else if (_rejections[_transactionId].count == 1) {
            require(
                _rejections[_transactionId].rejector1 != _rejector,
                "Already a rejector"
            );
            _rejections[_transactionId].rejector2 = _rejector;
        }
    }

    function _hasReachedLimit(
        uint256 _transactionId
    ) internal view returns (bool) {
        return
            _approvals[_transactionId].count == 2 ||
            _rejections[_transactionId].count == 2;
    }

    receive() external payable {}

    fallback() external payable {}

    function transactionCount() external view returns (uint256) {
        return _transactionCount;
    }

    function getOwnerCount() external view returns (uint256) {
        return _owners.length;
    }

    function getOwners() external view onlyOwner returns (address[] memory) {
        return _owners;
    }

    function getOwner(
        uint256 _index
    ) external view onlyOwner returns (address) {
        require(_index < _owners.length, "Invalid index");
        return _owners[_index];
    }

    function getTransaction(
        uint256 _transactionId
    ) external view onlyOwner returns (Transaction memory) {
        require(_transactionId < _transactionCount, "Invalid transaction id");
        return _transactions[_transactionId];
    }

    function getDeposit(
        address _owner
    ) external view onlyOwner returns (Deposit memory) {
        return _deposits[_owner];
    }

    function getApprovals(
        uint256 _transactionId
    ) external view onlyOwner returns (TransactionApprovals memory) {
        require(_transactionId < _transactionCount, "Invalid transaction id");
        return _approvals[_transactionId];
    }

    function getRejections(
        uint256 _transactionId
    ) external view onlyOwner returns (TransactionRejections memory) {
        require(_transactionId < _transactionCount, "Invalid transaction id");
        return _rejections[_transactionId];
    }

    function getBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function addOwner(address _owner) external onlyOwner {
        require(!_isOwner(_owner), "Already an owner");
        require(_owners.length < 3, "Max 3 owners");

        _owners.push(_owner);
        emit OwnerAdded(_owner);
    }

    function removeOwner(address _owner) external onlyOwner returns (bool) {
        require(_isOwner(_owner), "Not an owner");
        require(_owners.length > 2, "Min 2 owners");

        for (uint8 i = 0; i < _owners.length; i++) {
            if (_owners[i] == _owner) {
                require(i != 0, "Operation unauthorized");
                _owners[i] = _owners[_owners.length - 1];
                _owners.pop();

                emit OwnerRemoved(_owner);
                return true;
            }
        }
        return false;
    }

    function replaceOwner(
        address _oldOwner,
        address _newOwner
    ) external onlyOwner returns (bool) {
        require(_isOwner(_oldOwner), "Not an owner");
        require(!_isOwner(_newOwner), "Already an owner");

        for (uint8 i = 0; i < _owners.length; i++) {
            if (_owners[i] == _oldOwner) {
                _owners[i] = _newOwner;
                emit OwnerRemoved(_oldOwner);
                emit OwnerAdded(_newOwner);
                return true;
            }
        }
        return false;
    }

    function submit(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner {
        require(_to != address(0), "Invalid address");

        uint256 txId = _transactionCount++;

        _transactions[txId] = Transaction({
            from: msg.sender,
            to: _to,
            value: _value,
            data: _data,
            status: TransactionApprovalStatus.PENDING,
            approvals: 0,
            approvers: new address[](3),
            executed: false,
            executedAt: uint40(0),
            createdAt: uint40(block.timestamp)
        });

        emit TransactionSubmitted(msg.sender, txId, uint40(block.timestamp));
    }

    function approve(
        uint256 _transactionId
    ) external onlyOwner onlyPendingTransaction(_transactionId) {
        require(
            msg.sender != _transactions[_transactionId].from,
            "Operation unauthorized"
        );

        _approvals[_transactionId].count++;
        _addApprover(_transactionId, msg.sender);

        if (
            _hasReachedLimit(_transactionId) &&
            _approvals[_transactionId].count > _rejections[_transactionId].count
        ) {
            _transactions[_transactionId].status = TransactionApprovalStatus
                .APPROVED;
            _transactions[_transactionId].approvals++;
            _transactions[_transactionId].approvers = [
                _approvals[_transactionId].approver1,
                _approvals[_transactionId].approver2
            ];

            // Remove approvals
            delete _approvals[_transactionId];
        }

        emit TransactionApproved(msg.sender, _transactionId);
    }

    function reject(
        uint256 _transactionId
    ) external onlyOwner onlyPendingTransaction(_transactionId) {
        require(
            msg.sender != _transactions[_transactionId].from,
            "Operation unauthorized"
        );

        _rejections[_transactionId].count++;
        _addRejector(_transactionId, msg.sender);

        if (
            _hasReachedLimit(_transactionId) &&
            _rejections[_transactionId].count > _approvals[_transactionId].count
        ) {
            _transactions[_transactionId].status = TransactionApprovalStatus
                .REJECTED;
            delete _rejections[_transactionId];
        }

        emit TransactionRejected(msg.sender, _transactionId);
    }

    function deposit() external payable onlyOwner {
        require(msg.value > 0, "Invalid amount");

        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        require(success, "Deposit failed");

        _deposits[msg.sender] = Deposit({
            owner: msg.sender,
            amount: msg.value,
            createdAt: uint40(block.timestamp)
        });

        emit DepositMade(msg.sender, msg.value);
    }

    function execute(uint256 _transactionId) external onlyOwner {
        require(_transactionId < _transactionCount, "Invalid transaction id");

        Transaction storage _tx = _transactions[_transactionId];

        require(msg.sender == _tx.from, "Not the transaction owner");
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
}
