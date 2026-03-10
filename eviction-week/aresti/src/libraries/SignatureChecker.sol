// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

library SignatureChecker {
    error InvalidSignatureLength();
    error InvalidSignatureS();
    error InvalidSignature();

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address signer) {
        if (signature.length != 65) revert InvalidSignatureLength();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert InvalidSignatureS();
        }

        signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) revert InvalidSignature();
    }
}
