// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibSVG} from "../libraries/LibSVG.sol";
import {ISmokeNFTFacet} from "../interfaces/ISmokeNFTFacet.sol";

/// @title SmokeNFTFacet
/// @notice A diamond-compatible ERC-721 facet that mints fully on-chain generative
///         NFTs whose SVG artwork (animated smoke/fire) is deterministically derived
///         from the minter's address via LibSVG.
///
///         Diamond storage pattern is used so this facet can coexist with others
///         without storage slot collisions.
///
///         Compliance:
///           - ERC-721 core + Metadata + Enumerable (no OpenZeppelin)
///           - ERC-165 interface detection
///           - EIP-2535 diamond-compatible (no constructor, delegatecall-safe)
///
///         Rules:
///           - One mint per address (visual is permanently tied to minter address)
///           - NOT soulbound: transferable like any standard ERC-721 token
///           - No external dependencies; no IPFS; artwork is 100% on-chain
contract SmokeNFTFacet is ISmokeNFTFacet {
    constructor(address owner) {
        LibAppStorage.AppStorage storage as_ = LibAppStorage._appStorage();
        if (as_.initialised) return;

        as_.collectionName = "SmokeNFT";
        as_.collectionSymbol = "SMOKE";
        as_.nextTokenId = 1;
        as_.diamondOwner = owner;
        as_.initialised = true;
    }

    function initialize(string memory name, string memory symbol, address owner) external {
        LibAppStorage.AppStorage storage as_ = LibAppStorage._appStorage();
        if (as_.initialised) return;

        as_.collectionName = name;
        as_.collectionSymbol = symbol;
        as_.nextTokenId = 1;
        as_.diamondOwner = owner;
        as_.initialised = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Modifiers
    // ─────────────────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(
            msg.sender == LibAppStorage._appStorage().diamondOwner,
            "SmokeNFT: Not owner"
        );
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(
            LibAppStorage._appStorage().owners[tokenId] != address(0),
            "SmokeNFT: Token does not exist"
        );
        _;
    }

    /// @notice Query if the contract implements an interface
    /// @param  interfaceId The 4-byte interface selector
    /// @return True if supported
    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == type(ISmokeNFTFacet).interfaceId ||
            interfaceId == 0x80ac58cd || // ERC-721
            interfaceId == 0x5b5e139f || // ERC-721 Metadata
            interfaceId == 0x780e9d63; // ERC-721 Enumerable
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ERC-721 core read
    // ─────────────────────────────────────────────────────────────────────────

    /// @inheritdoc ISmokeNFTFacet
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "SmokeNFT: Zero address");
        return LibAppStorage._appStorage().balances[owner];
    }

    /// @inheritdoc ISmokeNFTFacet
    function ownerOf(
        uint256 tokenId
    ) external view override tokenExists(tokenId) returns (address) {
        return LibAppStorage._appStorage().owners[tokenId];
    }

    /// @inheritdoc ISmokeNFTFacet
    function getApproved(
        uint256 tokenId
    ) external view override tokenExists(tokenId) returns (address) {
        return LibAppStorage._appStorage().tokenApprovals[tokenId];
    }

    /// @inheritdoc ISmokeNFTFacet
    function isApprovedForAll(
        address owner,
        address operator
    ) external view override returns (bool) {
        return LibAppStorage._appStorage().operatorApprovals[owner][operator];
    }

    /// @inheritdoc ISmokeNFTFacet
    function setApprovalForAll(
        address operator,
        bool approved
    ) external override {
        require(operator != msg.sender, "SmokeNFT: approve to caller");
        LibAppStorage._appStorage().operatorApprovals[msg.sender][
            operator
        ] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc ISmokeNFTFacet
    function approve(address to, uint256 tokenId) external override {
        LibAppStorage.AppStorage storage as_ = LibAppStorage._appStorage();
        address owner = as_.owners[tokenId];
        require(msg.sender == owner || as_.operatorApprovals[owner][msg.sender], "SmokeNFT: not approved");
        as_.tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @inheritdoc ISmokeNFTFacet
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "SmokeNFT: not approved"
        );
        _transfer(from, to, tokenId);
    }

    /// @inheritdoc ISmokeNFTFacet
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, ""),
            "SmokeNFT: non-ERC721Receiver"
        );
    }

    /// @inheritdoc ISmokeNFTFacet
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "SmokeNFT: non-ERC721Receiver"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ERC-721 Metadata
    // ─────────────────────────────────────────────────────────────────────────

    /// @inheritdoc ISmokeNFTFacet
    function name() external view override returns (string memory) {
        return LibAppStorage._appStorage().collectionName;
    }

    /// @inheritdoc ISmokeNFTFacet
    function symbol() external view override returns (string memory) {
        return LibAppStorage._appStorage().collectionSymbol;
    }

    /// @inheritdoc ISmokeNFTFacet
    function tokenURI(
        uint256 tokenId
    ) external view override tokenExists(tokenId) returns (string memory) {
        address minter = LibAppStorage._appStorage().tokenMinter[tokenId];
        string memory svg = LibSVG.generateSVG(minter);
        string memory svgB64 = _base64Encode(bytes(svg));

        (
            bool fireMode,
            bool driftLeft,
            bool swirl,
            uint8 plumeCount,
            string memory colorA,
            string memory colorB,
            string memory colorAccent
        ) = LibSVG.describeStyle(minter);

        string memory attrs = _buildAttributes(fireMode, driftLeft, swirl, plumeCount, colorA, colorB, colorAccent);
        string memory json = _buildJSON(tokenId, svgB64, attrs);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    _base64Encode(bytes(json))
                )
            );
    }

    function _buildAttributes(
        bool fireMode,
        bool driftLeft,
        bool swirl,
        uint8 plumeCount,
        string memory colorA,
        string memory colorB,
        string memory colorAccent
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "[",
                '{"trait_type":"Type","value":"',
                fireMode ? "Fire" : "Smoke",
                '"},',
                '{"trait_type":"Drift","value":"',
                driftLeft ? "Left" : "Right",
                '"},',
                '{"trait_type":"Swirl","value":"',
                swirl ? "Yes" : "No",
                '"},',
                '{"trait_type":"Plumes","value":',
                _uint2str(plumeCount),
                "},",
                '{"trait_type":"Primary Color","value":"',
                colorA,
                '"},',
                '{"trait_type":"Secondary Color","value":"',
                colorB,
                '"},',
                '{"trait_type":"Accent Color","value":"',
                colorAccent,
                '"}',
                "]"
            )
        );
    }

    function _buildJSON(
        uint256 tokenId,
        string memory svgB64,
        string memory attrs
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"name":"SmokeNFT #',
                _uint2str(tokenId),
                '",',
                '"description":"Fully on-chain generative smoke \\u0026 fire NFT. Artwork derived from minter address_.",',
                '"image":"data:image/svg+xml;base64,',
                svgB64,
                '",',
                '"attributes":',
                attrs,
                "}"
            )
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ERC-721 Enumerable
    // ─────────────────────────────────────────────────────────────────────────

    /// @inheritdoc ISmokeNFTFacet
    function totalSupply() external view override returns (uint256) {
        return LibAppStorage._appStorage().allTokens.length;
    }

    /// @inheritdoc ISmokeNFTFacet
    function tokenByIndex(
        uint256 index
    ) external view override returns (uint256) {
        require(
            index < LibAppStorage._appStorage().allTokens.length,
            "SmokeNFT: index out of bounds"
        );
        return LibAppStorage._appStorage().allTokens[index];
    }

    /// @inheritdoc ISmokeNFTFacet
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view override returns (uint256) {
        require(
            index < LibAppStorage._appStorage().ownedTokens[owner].length,
            "SmokeNFT: owner index out of bounds"
        );
        return LibAppStorage._appStorage().ownedTokens[owner][index];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SmokeNFT-specific reads
    // ─────────────────────────────────────────────────────────────────────────

    /// @inheritdoc ISmokeNFTFacet
    function tokenSVG(
        uint256 tokenId
    ) external view override tokenExists(tokenId) returns (string memory) {
        return
            LibSVG.generateSVG(
                LibAppStorage._appStorage().tokenMinter[tokenId]
            );
    }

    /// @inheritdoc ISmokeNFTFacet
    function minterOf(
        uint256 tokenId
    ) external view override tokenExists(tokenId) returns (address) {
        return LibAppStorage._appStorage().tokenMinter[tokenId];
    }

    /// @inheritdoc ISmokeNFTFacet
    function styleOf(
        uint256 tokenId
    )
        external
        view
        override
        tokenExists(tokenId)
        returns (
            bool fireMode,
            bool driftLeft,
            bool swirl,
            uint8 plumeCount,
            string memory colorA,
            string memory colorB,
            string memory colorAccent
        )
    {
        return
            LibSVG.describeStyle(
                LibAppStorage._appStorage().tokenMinter[tokenId]
            );
    }

    /// @inheritdoc ISmokeNFTFacet
    function hasMinted(address minter) external view override returns (bool) {
        return LibAppStorage._appStorage().minterToTokenId[minter] != 0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Minting
    // ─────────────────────────────────────────────────────────────────────────

    /// @inheritdoc ISmokeNFTFacet
    function mint() external override returns (uint256 tokenId) {
        LibAppStorage.AppStorage storage as_ = LibAppStorage._appStorage();
        require(
            as_.minterToTokenId[msg.sender] == 0,
            "SmokeNFT: already minted"
        );

        tokenId = as_.nextTokenId++;
        as_.minterToTokenId[msg.sender] = tokenId;
        as_.tokenMinter[tokenId] = msg.sender;

        _mint(msg.sender, tokenId);

        // Derive style traits for the event
        (
            bool fireMode,
            bool driftLeft,
            bool swirl,
            uint8 plumeCount,
            ,
            ,

        ) = LibSVG.describeStyle(msg.sender);

        emit SmokeMinted(
            msg.sender,
            tokenId,
            fireMode,
            driftLeft,
            swirl,
            plumeCount
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Admin
    // ─────────────────────────────────────────────────────────────────────────

    /// @inheritdoc ISmokeNFTFacet
    function setNameAndSymbol(
        string calldata newName,
        string calldata newSymbol
    ) external override onlyOwner {
        LibAppStorage._appStorage().collectionName = newName;
        LibAppStorage._appStorage().collectionSymbol = newSymbol;
        emit MetadataUpdated(newName, newSymbol);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Internal transfer logic
    // ─────────────────────────────────────────────────────────────────────────

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "SmokeNFT: mint to zero address");

        LibAppStorage.AppStorage storage as_ = LibAppStorage._appStorage();
        as_.owners[tokenId] = to;
        as_.balances[to] += 1;

        // Enumerable bookkeeping
        as_.allTokensIndex[tokenId] = as_.allTokens.length;
        as_.allTokens.push(tokenId);

        as_.ownedTokensIndex[tokenId] = as_.ownedTokens[to].length;
        as_.ownedTokens[to].push(tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        LibAppStorage.AppStorage storage as_ = LibAppStorage._appStorage();
        require(
            as_.owners[tokenId] == from,
            "SmokeNFT: transfer from wrong owner"
        );
        require(to != address(0), "SmokeNFT: transfer to zero address");

        // Clear approval
        delete as_.tokenApprovals[tokenId];

        // Balance update
        as_.balances[from] -= 1;
        as_.balances[to] += 1;
        as_.owners[tokenId] = to;

        // Enumerable: remove from `from`, add to `to`
        _removeFromOwnedTokens(from, tokenId);
        as_.ownedTokensIndex[tokenId] = as_.ownedTokens[to].length;
        as_.ownedTokens[to].push(tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _removeFromOwnedTokens(address owner, uint256 tokenId) internal {
        LibAppStorage.AppStorage storage as_ = LibAppStorage._appStorage();
        uint256 idx = as_.ownedTokensIndex[tokenId];
        uint256 lastIdx = as_.ownedTokens[owner].length - 1;

        if (idx != lastIdx) {
            uint256 lastTokenId = as_.ownedTokens[owner][lastIdx];
            as_.ownedTokens[owner][idx] = lastTokenId;
            as_.ownedTokensIndex[lastTokenId] = idx;
        }
        as_.ownedTokens[owner].pop();
        delete as_.ownedTokensIndex[tokenId];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        LibAppStorage.AppStorage storage as_ = LibAppStorage._appStorage();
        address owner = as_.owners[tokenId];
        return (spender == owner ||
            as_.tokenApprovals[tokenId] == spender ||
            as_.operatorApprovals[owner][spender]);
    }

    /// @dev ERC-721 receiver check — only called when `to` is a contract
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        uint256 size;
        assembly ("memory-safe") {
            size := extcodesize(to)
        }
        if (size == 0) return true;

        (bool succeas, bytes memory returndata) = to.call(
            abi.encodeWithSelector(
                0x150b7a02, // onERC721Received(address,address,uint256,bytes)
                msg.sender,
                from,
                tokenId,
                data
            )
        );
        if (!succeas) {
            if (returndata.length > 0) {
                assembly ("memory-safe") {
                    let rds := mload(returndata)
                    revert(add(32, returndata), rds)
                }
            }
            return false;
        }
        return abi.decode(returndata, (bytes4)) == 0x150b7a02;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Utilities
    // ─────────────────────────────────────────────────────────────────────────

    function _uint2str(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint256 tmp = v;
        uint256 digits;
        while (tmp != 0) {
            digits++;
            tmp /= 10;
        }
        bytes memory buf = new bytes(digits);
        while (v != 0) {
            digits--;
            buf[digits] = bytes1(uint8(48 + (v % 10)));
            v /= 10;
        }
        return string(buf);
    }

    /// @dev Base64 encoding — RFC 4648 table, no padding
    function _base64Encode(
        bytes memory data
    ) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string
            memory TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        bytes memory table = bytes(TABLE);

        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);

        uint256 i;
        uint256 j;
        for (; i + 2 < data.length; i += 3) {
            uint24 input = (uint24(uint8(data[i])) << 16) |
                (uint24(uint8(data[i + 1])) << 8) |
                uint24(uint8(data[i + 2]));
            result[j++] = table[(input >> 18) & 0x3F];
            result[j++] = table[(input >> 12) & 0x3F];
            result[j++] = table[(input >> 6) & 0x3F];
            result[j++] = table[input & 0x3F];
        }

        if (data.length - i == 2) {
            uint24 input = (uint24(uint8(data[i])) << 16) |
                (uint24(uint8(data[i + 1])) << 8);
            result[j++] = table[(input >> 18) & 0x3F];
            result[j++] = table[(input >> 12) & 0x3F];
            result[j++] = table[(input >> 6) & 0x3F];
            result[j++] = bytes1("=");
        } else if (data.length - i == 1) {
            uint24 input = uint24(uint8(data[i])) << 16;
            result[j++] = table[(input >> 18) & 0x3F];
            result[j++] = table[(input >> 12) & 0x3F];
            result[j++] = bytes1("=");
            result[j++] = bytes1("=");
        }

        return string(result);
    }
}
