// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IARESTreasury} from "../interfaces/IARESTreasury.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ARESTreasury is IARESTreasury, ReentrancyGuard {
    address public immutable i_queue;
    
    // Large Treasury Drain defense: Max daily withdrawal (5% of treasury limit)
    uint256 public constant MAX_DAILY_WITHDRAWAL_BPS = 500; // 5%
    uint256 public constant RATE_LIMIT_PERIOD = 1 days;

    uint256 private _periodStart;
    uint256 private _periodWithdrawn;

    modifier onlyQueue() {
        _onlyQueue();
        _;
    }

    function _onlyQueue() internal view {
        require(msg.sender == i_queue, Unauthorized());
    }

    constructor(address _queue) {
        i_queue = _queue;
        _periodStart = block.timestamp;
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata payload
    ) external onlyQueue nonReentrant returns (bytes memory) {
        if (value > 0) {
            _checkRateLimit(value, address(this).balance - value);
        }

        (bool success, bytes memory result) = target.call{value: value}(payload);
        require(success, TransferFailed());

        emit Executed(target, value, payload);
        return result;
    }

    function _checkRateLimit(uint256 amount, uint256 balanceBefore) internal {
        if (block.timestamp >= _periodStart + RATE_LIMIT_PERIOD) {
            _periodStart = block.timestamp;
            _periodWithdrawn = 0;
        }
        
        uint256 limit = (balanceBefore * MAX_DAILY_WITHDRAWAL_BPS) / 10000;
        _periodWithdrawn += amount;
        require(_periodWithdrawn <= limit, RateLimitExceeded());
    }

    receive() external payable {}
}
