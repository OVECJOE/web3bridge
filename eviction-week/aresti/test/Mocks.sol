// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract MockARESToken is ERC20, ERC20Permit, ERC20Votes {
    constructor() ERC20("ARES", "ARES") ERC20Permit("ARES") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }
}

contract MaliciousTarget {
    address public treasury;

    constructor(address _treasury) {
        treasury = _treasury;
    }

    receive() external payable {}
    
    function fallbackCall() external payable {
        // Try to re-enter treasury. It should fail due to nonReentrant.
        (bool success, ) = treasury.call(
            abi.encodeWithSignature("execute(address,uint256,bytes)", address(this), 1 ether, "")
        );
        require(success, "Reentrancy blocked");
    }
}
