// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Tault} from "./Tault.sol";
import {TaultNFT} from "./TaultNFT.sol";

contract TaultFactory {
    // Errors
    error VaultAlreadyExists();
    error ZeroAddress();

    // Events
    event VaultCreated(
        address indexed token,
        address indexed vault,
        uint256 tokenId
    );

    TaultNFT public immutable nft;
    mapping(address => address) public vaults;
    address[] public allVaults;

    constructor() {
        nft = new TaultNFT(address(this));
    }

    function createVault(address _token) external returns (address vault) {
        require(vaults[_token] == address(0), VaultAlreadyExists());

        bytes32 salt = keccak256(abi.encodePacked(_token));
        vault = address(new Tault{salt: salt}(_token, msg.sender));

        vaults[_token] = vault;
        allVaults.push(vault);

        uint256 tokenId = nft.mint(msg.sender, vault);

        emit VaultCreated(_token, vault, tokenId);
    }

    function predictVaultAddress(
        address _token
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_token));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(
                    abi.encodePacked(
                        type(Tault).creationCode,
                        abi.encode(_token, address(0))
                    )
                )
            )
        );

        return address(uint160(uint256(hash)));
    }
}
