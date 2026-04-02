// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibAppStorage {
    struct AppStorage {
        mapping(uint256 => address) owners;
        mapping(address => uint256) balances;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(uint256 => address) tokenMinter;
        mapping(address => uint256) minterToTokenId;
        uint256[] allTokens;
        mapping(uint256 => uint256) allTokensIndex;
        mapping(address => uint256[]) ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
        string collectionName;
        string collectionSymbol;
        uint256 nextTokenId;
        address diamondOwner;
        bool initialised;
    }

    function _appStorage() internal pure returns (AppStorage storage as_) {
        bytes32 position = keccak256("diamond.standard.app.storage");
        assembly {
            as_.slot := position
        }
    }
}
