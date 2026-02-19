// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract TwoBottles {
    // ============= Events =============
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event TransferFeeCollected(address indexed from, uint256 feeAmount);

    // ============= Constants ============
    uint8 constant DECIMALS = 18;
    uint256 constant BASIS_POINTS = 10000; // 100% = 10000 basis points
    uint256 constant TRANSFER_FEE_BPS = 200; // 2% fee
    uint8 constant NOT_ENTERED = 1;
    uint8 constant ENTERED = 2;

    // ============= State Variables =============
    address public owner;
    uint8 private _status;
    uint256 private _totalSupply = 1000000 * 10 ** DECIMALS; // 1 million tokens with 18 decimals
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ============= Constructor =============

    constructor() {
        owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // ============= Modifiers =============
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Address cannot be zero");
        _;
    }

    modifier nonReentrant() {
        require(_status != ENTERED, "Reentrant call");
        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }

    // ============= ERC20 View/Pure Functions =============

    function name() external pure returns (string memory) {
        return "2Bottles";
    }

    function symbol() external pure returns (string memory) {
        return "2BTL";
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // ============= Pure Functions =============

    function calculateTransferFee(uint256 _amount) public pure returns (uint256) {
        return (_amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
    }

    function calculateAmountAfterFee(uint256 _amount) public pure returns (uint256) {
        uint256 fee = calculateTransferFee(_amount);
        return _amount - fee;
    }

    // ============= ERC20 Functions =============

    function balanceOf(address _account) external view returns (uint256) {
        return _balances[_account];
    }

    function transfer(address _to, uint256 _amount) external nonReentrant returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external nonReentrant returns (bool) {
        require(
            _allowances[_from][msg.sender] >= _amount,
            "Insufficient allowance"
        );

        unchecked {
            _allowances[_from][msg.sender] -= _amount;
        }

        _transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(
            _balances[msg.sender] >= _value,
            "Cannot approve more than balance"
        );
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function mint(address _to, uint256 _amount) external onlyOwner nonZeroAddress(_to) {
        unchecked {
            _balances[_to] += _amount;
            _totalSupply += _amount;
        }

        emit Transfer(address(0), _to, _amount);
    }

    function burn(uint256 _amount) external {
        require(_balances[msg.sender] >= _amount, "Insufficient balance to burn");

        unchecked {
            _balances[msg.sender] -= _amount;
            _totalSupply -= _amount;
        }

        emit Transfer(msg.sender, address(0), _amount);
    }

    // ============= Internal =============

    function _transfer(address _from, address _to, uint256 _amount) internal nonZeroAddress(_to) {
        require(_balances[_from] >= _amount, "Insufficient balance");
        require(_from != _to, "Cannot transfer to self");

        // Calculate fee
        uint256 fee = (_amount * TRANSFER_FEE_BPS) / BASIS_POINTS;
        uint256 amountAfterFee = _amount - fee;

        unchecked {
            _balances[_from] -= _amount;
            _balances[_to] += amountAfterFee;
        }

        // Fee to treasury (contract address)
        if (fee > 0) {
            _balances[address(this)] += fee;
            emit TransferFeeCollected(_from, fee);
            emit Transfer(_from, address(this), fee);
        }

        emit Transfer(_from, _to, amountAfterFee);
    }
}
