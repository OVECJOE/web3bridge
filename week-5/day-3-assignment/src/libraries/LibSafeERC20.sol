// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IERC20 } from "../interfaces/IERC20.sol";

/**
 * @title LibSafeERC20
 * @notice Safe ERC20 transfer wrappers that handle non-standard return values
 * @dev Some tokens (like USDT) do not return bool for transfer/approve.
        This library handles both complaint and non-complaint tokens gracefully.
*/
library LibSafeERC20 {
    function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal {
        _callOptionalReturn(_token, abi.encodeCall(_token.transfer, (_to, _amount)));
    }

    function safeTransferFrom(IERC20 _token, address _from, address _to, uint256 _amount) internal {
        _callOptionalReturn(_token, abi.encodeCall(_token.transferFrom, (_from, _to, _amount)));
    }

    function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal {
        // if setting non-zero, first set to 0 (for USDT-like tokens)
        if (_amount > 0) {
            uint256 currentAllowance = _token.allowance(address(this), _spender);
            if (currentAllowance > 0) {
                _callOptionalReturn(_token, abi.encodeCall(_token.approve, (_spender, 0)));
            }
        }
        _callOptionalReturn(_token, abi.encodeCall(_token.approve, (_spender, _amount)));
    }

    function _callOptionalReturn(IERC20 _token, bytes memory _data) private {
        (bool success, bytes memory returndata) = address(_token).call(_data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
