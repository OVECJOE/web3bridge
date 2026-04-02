// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ISmokeNFTFacet
/// @notice Interface for the SmokeNFT diamond facet — a fully on-chain generative
///         NFT where every token's SVG artwork is derived from the minter's address.
///         Follows ERC-721 with metadata extensions. NOT soulbound — tokens are
///         freely transferable.
interface ISmokeNFTFacet {
    // ─────────────────────────────────────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev ERC-721 transfer (also covers mint when `from` == address(0) and
    ///      burn when `to` == address(0)).
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @dev ERC-721 single-token approval
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /// @dev ERC-721 operator approval
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @dev Emitted when a new SmokeNFT is minted
    event SmokeMinted(
        address indexed minter,
        uint256 indexed tokenId,
        bool fireMode,
        bool driftLeft,
        bool swirl,
        uint8 plumeCount
    );

    /// @dev Emitted when the contract name/symbol is updated by the owner
    event MetadataUpdated(string name, string symbol);

    // ─────────────────────────────────────────────────────────────────────────
    // ERC-721 core
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Count of all NFTs assigned to `owner`
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Find the owner of `tokenId`
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Transfers `tokenId` from `from` to `to` with safety check
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /// @notice Transfers `tokenId` from `from` to `to` with safety check (no data)
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Transfer ownership of `tokenId` to `to`
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Set or reaffirm the approved address for a single NFT
    function approve(address to, uint256 tokenId) external;

    /// @notice Enable or disable approval for a third party operator
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Get the approved address for a single NFT
    function getApproved(uint256 tokenId) external view returns (address);

    /// @notice Query if an address is an authorised operator for another
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    // ─────────────────────────────────────────────────────────────────────────
    // ERC-721 Metadata extension
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Query if the contract implements an interface
    /// @param  interfaceId The 4-byte interface selector
    /// @return True if supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// @notice A descriptive name for a collection of NFTs
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    ///         Returns a data URI containing a base64-encoded JSON blob with an
    ///         embedded on-chain SVG image. No IPFS or external URLs required.
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ─────────────────────────────────────────────────────────────────────────
    // ERC-721 Enumerable extension
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Count of tokens tracked by this contract
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs — returns tokenId at `index` in global list
    function tokenByIndex(uint256 index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);

    // ─────────────────────────────────────────────────────────────────────────
    // SmokeNFT-specific read functions
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Returns the on-chain SVG for a given token
    function tokenSVG(uint256 tokenId) external view returns (string memory);

    /// @notice Returns the minter (original creator) address for `tokenId`
    ///         The minter determines the token's permanent visual style.
    function minterOf(uint256 tokenId) external view returns (address);

    /// @notice Describe the visual style traits for a given token
    /// @return fireMode    True if the token displays fire rather than smoke
    /// @return driftLeft   True if the plumes drift leftward
    /// @return swirl       True if swirling turbulence is applied
    /// @return plumeCount  Number of smoke/fire plume paths (2-6)
    /// @return colorA      Hex string for primary color (#rrggbb)
    /// @return colorB      Hex string for secondary color (#rrggbb)
    /// @return colorAccent Hex string for accent / ember color (#rrggbb)
    function styleOf(
        uint256 tokenId
    )
        external
        view
        returns (
            bool fireMode,
            bool driftLeft,
            bool swirl,
            uint8 plumeCount,
            string memory colorA,
            string memory colorB,
            string memory colorAccent
        );

    /// @notice Whether a given address has already minted
    function hasMinted(address minter) external view returns (bool);

    // ─────────────────────────────────────────────────────────────────────────
    // Minting
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Mint a SmokeNFT to the caller.
    ///         Each address may mint at most once (visual is tied to minter address).
    ///         No payment required. Not soulbound — freely transferable after mint.
    /// @return tokenId The ID of the newly minted token
    function mint() external returns (uint256 tokenId);

    // ─────────────────────────────────────────────────────────────────────────
    // Admin
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Update the collection name and symbol (diamond owner only)
    function setNameAndSymbol(
        string calldata newName,
        string calldata newSymbol
    ) external;
}
