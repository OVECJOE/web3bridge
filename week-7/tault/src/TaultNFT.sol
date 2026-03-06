// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SVGLib} from "./libraries/SVGLib.sol";
import {Tault} from "./Tault.sol";

contract TaultNFT is ERC721, Ownable {
    uint256 private _nextTokenId;
    mapping(uint256 => address) public vaultOf;
    mapping(address => uint256) public tokenIdOf;

    constructor(
        address _factory
    ) ERC721("Tault NFT", "TAULT") Ownable(_factory) {}

    function mint(
        address _to,
        address _vault
    ) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        vaultOf[tokenId] = _vault;
        tokenIdOf[_vault] = tokenId;

        _safeMint(_to, tokenId);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        address vault = vaultOf[_tokenId];
        IERC20Metadata token = IERC20Metadata(address(Tault(vault).token()));
        return
            SVGLib.qrCodeGenerateTokenURI(
                token.name(),
                token.symbol(),
                address(token),
                vault,
                Tault(vault).totalLiquidity(),
                token.decimals()
            );
    }
}
