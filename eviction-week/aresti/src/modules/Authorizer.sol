// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IAuthorizer} from "../interfaces/IAuthorizer.sol";
import {SignatureChecker} from "../libraries/SignatureChecker.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Authorizer is IAuthorizer, Ownable {
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;
    
    mapping(address => uint256) private _nonces;

    constructor(
        string memory name,
        string memory version,
        address initialOwner
    ) Ownable(initialOwner) {
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                _TYPE_HASH,
                _hashedName,
                _hashedVersion,
                block.chainid,
                address(this)
            )
        );
    }

    function consumeNonce(address account) external onlyOwner returns (uint256) {
        uint256 nonce = _nonces[account];
        _nonces[account] = nonce + 1;
        return nonce;
    }

    function getNonce(address account) external view returns (uint256) {
        return _nonces[account];
    }

    function verifyAuth(
        address account,
        bytes32 structHash,
        bytes calldata signature
    ) external view {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash)
        );
        address signer = SignatureChecker.recover(digest, signature);
        if (signer != account) revert InvalidSigner();
    }
}
