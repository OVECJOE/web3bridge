// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title MeowelotNFT
/// @notice Soulbound ERC721 with fully on-chain SVG ocelot art.
///        Minted automatically by MeowelotToken on transfers >= 10,000 $MEOW.
contract MeowelotNFT is ERC721, Ownable {
    using Strings for uint256;

    address public tokenContract;
    uint256 private _tokenIdCounter;

    struct OcelotTraits {
        uint8 fur; // 0-4 fur pattern
        uint8 eyes; // 0-3 eye color
        uint8 background; // 0-4 bg color
        uint8 accessory; // 0-3 accessory type
        uint256 amount; // transfer amount that triggered mint
        address recipient;
        uint256 mintedAt;
    }

    mapping(uint256 => OcelotTraits) public traits;

    string[5] private FUR = ["Golden Spotted","Midnight Black","Snow Drift","Rust Ember","Jungle Shadow"];
    string[4] private EYES = ["Amber Blaze","Glacial Blue","Emerald Wild","Void Crimson"];
    string[5] private BACKGROUNDS = ["Canopy Green","Dusk Purple","Desert Sand","Midnight Navy","Crimson Dawn"];
    string[4] private ACCESSORIES = ["Crown","Bandana","Monocle","None"];
    string[5] private BG_COLORS = ["#1a3a2a","#2d1b4e","#8b6914","#0d1f3c","#4a0f0f"];
    string[5] private FUR_COLORS = ["#c8852a","#1a1a1a","#e8e0d0","#b84020","#2d4a1a"];
    string[5] private SPOT_COLORS = ["#7a4a10","#333333","#a89878","#6a1a08","#162408"];
    string[4] private EYE_COLORS = ["#f0a030","#80c8f0","#40c060","#cc2020"];

    event OcelotMinted(uint256 indexed tokenId, address indexed recipient, uint256 amount);
    
    error OnlyTokenContract();
    error Soulbound();
    error ZeroAddress();

    constructor(address _initialOwner) ERC721("Meowelot Ocelot", "OCELOT") Ownable(_initialOwner) {}

    modifier onlyTokenContract() {
        if (msg.sender != tokenContract) revert OnlyTokenContract();
        _;
    }

    function setTokenContract(address _tokenContract) external onlyOwner {
        if (_tokenContract == address(0)) revert ZeroAddress();
        tokenContract = _tokenContract;
    }

    function mintOcelot(address _recipient, uint256 _amount, uint256 seed) external onlyTokenContract returns (uint256) {
        uint256 tokenId = ++_tokenIdCounter;

        traits[tokenId] = OcelotTraits({
            fur: uint8(seed % 5),
            eyes: uint8((seed >> 8) % 4),
            background: uint8((seed >> 16) % 5),
            accessory: uint8((seed >> 24) % 4),
            amount: _amount,
            recipient: _recipient,
            mintedAt: block.timestamp
        });

        _safeMint(_recipient, tokenId);
        emit OcelotMinted(tokenId, _recipient, _amount);
        return tokenId;
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        // Soulbound: allow mint (from == 0) and burn (to == 0), block transfers.
        if (from != address(0) && to != address(0)) revert Soulbound();
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        OcelotTraits memory t = traits[tokenId];

        string memory svg = _buildSVG(t, tokenId);
        string memory json = string.concat(
            '{"name":"Meowelot Ocelot #', tokenId.toString(), '",',
            '"description":"A soulbound Meowelot ocelot earned by transferring >= 10,000 $MEOW.",',
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
            '"attributes":[',
                '{"trait_type":"Fur","value":"',        FUR[t.fur],        '"},',
                '{"trait_type":"Eyes","value":"',       EYES[t.eyes],      '"},',
                '{"trait_type":"Background","value":"', BACKGROUNDS[t.background], '"},',
                '{"trait_type":"Accessory","value":"',  ACCESSORIES[t.accessory],  '"},',
                '{"trait_type":"Transfer Amount","value":', (t.amount / 1e18).toString(), '}',
            ']}'
        );

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        );
    }

    function _buildSVG(OcelotTraits memory t, uint256 tokenId) internal view returns (string memory) {
        string memory bgColor  = BG_COLORS[t.background];
        string memory furColor = FUR_COLORS[t.fur];
        string memory spotColor= SPOT_COLORS[t.fur];
        string memory eyeColor = EYE_COLORS[t.eyes];

        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">',
            '<defs>',
            '<radialGradient id="bg" cx="50%" cy="50%" r="70%">',
            '<stop offset="0%" stop-color="', bgColor, '" stop-opacity="0.8"/>',
            '<stop offset="100%" stop-color="', bgColor, '"/>',
            '</radialGradient>',
            '</defs>',

            '<rect width="300" height="300" fill="url(#bg)"/>',
            _buildStars(tokenId),
            _buildBody(furColor, spotColor),
            _buildFace(furColor, spotColor, eyeColor),
            _buildAccessory(t.accessory, furColor),
            _buildLabel(tokenId, t.amount),
            '</svg>'
        );
    }

    function _buildStars(uint256 seed) internal pure returns (string memory) {
        // 8 tiny star dots for atmosphere
        string memory s = "";
        for (uint i = 0; i < 8; i++) {
            uint256 h = uint256(keccak256(abi.encodePacked(seed, i)));
            uint x = 10 + (h % 280);
            uint y = 10 + ((h >> 8) % 100);
            s = string.concat(s, '<circle cx="', x.toString(), '" cy="', y.toString(), '" r="1.5" fill="white" opacity="0.6"/>');
        }
        return s;
    }

    function _buildBody(string memory fur, string memory spot) internal pure returns (string memory) {
        return string.concat(

            '<ellipse cx="150" cy="210" rx="65" ry="55" fill="', fur, '"/>',

            '<path d="M215 230 Q270 200 260 160 Q255 145 245 155 Q248 175 220 195" fill="', fur, '" stroke="', spot, '" stroke-width="2"/>',

            '<ellipse cx="130" cy="200" rx="8" ry="10" fill="', spot, '" opacity="0.7"/>',
            '<ellipse cx="165" cy="215" rx="7" ry="9" fill="', spot, '" opacity="0.7"/>',
            '<ellipse cx="145" cy="235" rx="6" ry="8" fill="', spot, '" opacity="0.6"/>',
            '<ellipse cx="175" cy="195" rx="9" ry="7" fill="', spot, '" opacity="0.7"/>',

            '<ellipse cx="120" cy="255" rx="18" ry="12" fill="', fur, '"/>',
            '<ellipse cx="178" cy="255" rx="18" ry="12" fill="', fur, '"/>',

            '<circle cx="111" cy="260" r="4" fill="', spot, '" opacity="0.5"/>',
            '<circle cx="120" cy="263" r="4" fill="', spot, '" opacity="0.5"/>',
            '<circle cx="129" cy="260" r="4" fill="', spot, '" opacity="0.5"/>',
            '<circle cx="169" cy="260" r="4" fill="', spot, '" opacity="0.5"/>',
            '<circle cx="178" cy="263" r="4" fill="', spot, '" opacity="0.5"/>',
            '<circle cx="187" cy="260" r="4" fill="', spot, '" opacity="0.5"/>'
        );
    }

    function _buildFace(string memory fur, string memory spot, string memory eye) internal pure returns (string memory) {
        return string.concat(

            '<ellipse cx="150" cy="148" rx="52" ry="48" fill="', fur, '"/>',

            '<polygon points="108,118 100,88 128,108" fill="', fur, '"/>',
            '<polygon points="113,115 108,92 128,110" fill="', spot, '" opacity="0.6"/>',
            '<polygon points="192,118 200,88 172,108" fill="', fur, '"/>',
            '<polygon points="187,115 192,92 172,110" fill="', spot, '" opacity="0.6"/>',

            '<ellipse cx="128" cy="142" rx="9" ry="11" fill="', spot, '" opacity="0.5"/>',
            '<ellipse cx="172" cy="142" rx="9" ry="11" fill="', spot, '" opacity="0.5"/>',

            '<ellipse cx="132" cy="145" rx="11" ry="9" fill="white"/>',
            '<ellipse cx="168" cy="145" rx="11" ry="9" fill="white"/>',
            '<ellipse cx="132" cy="145" rx="7" ry="7" fill="', eye, '"/>',
            '<ellipse cx="168" cy="145" rx="7" ry="7" fill="', eye, '"/>',
            '<ellipse cx="132" cy="145" rx="4" ry="5" fill="#111"/>',
            '<ellipse cx="168" cy="145" rx="4" ry="5" fill="#111"/>',
            '<circle cx="135" cy="143" r="2" fill="white"/>',
            '<circle cx="171" cy="143" r="2" fill="white"/>',

            '<polygon points="150,158 145,164 155,164" fill="#e06080"/>',

            '<path d="M145 164 Q150 170 155 164" fill="none" stroke="#c04060" stroke-width="1.5"/>',

            '<line x1="155" y1="162" x2="195" y2="155" stroke="white" stroke-width="1" opacity="0.7"/>',
            '<line x1="155" y1="165" x2="195" y2="165" stroke="white" stroke-width="1" opacity="0.7"/>',
            '<line x1="155" y1="168" x2="195" y2="175" stroke="white" stroke-width="1" opacity="0.7"/>',
            '<line x1="145" y1="162" x2="105" y2="155" stroke="white" stroke-width="1" opacity="0.7"/>',
            '<line x1="145" y1="165" x2="105" y2="165" stroke="white" stroke-width="1" opacity="0.7"/>',
            '<line x1="145" y1="168" x2="105" y2="175" stroke="white" stroke-width="1" opacity="0.7"/>'
        );
    }

    function _buildAccessory(uint8 accessory, string memory /*fur*/) internal pure returns (string memory) {
        if (accessory == 0) {
            // Crown
            return string.concat(
                '<polygon points="150,88 138,100 144,96 150,102 156,96 162,100" fill="#f0c020" stroke="#c09010" stroke-width="1"/>',
                '<circle cx="150" cy="90" r="3" fill="#ff4040"/>',
                '<circle cx="139" cy="99" r="2.5" fill="#4040ff"/>',
                '<circle cx="161" cy="99" r="2.5" fill="#40c040"/>'
            );
        } else if (accessory == 1) {
            // Bandana
            return string.concat(
                '<path d="M105 168 Q150 178 195 168 Q185 185 150 188 Q115 185 105 168Z" fill="#cc2020" opacity="0.85"/>',
                '<path d="M105 168 Q150 174 195 168" fill="none" stroke="#881010" stroke-width="1.5"/>'
            );
        } else if (accessory == 2) {
            // Monocle
            return string.concat(
                '<circle cx="168" cy="145" r="14" fill="none" stroke="#c0a020" stroke-width="2"/>',
                '<line x1="182" y1="148" x2="190" y2="155" stroke="#c0a020" stroke-width="1.5"/>'
            );
        }
        // None
        return "";
    }

    function _buildLabel(uint256 tokenId, uint256 amount) internal pure returns (string memory) {
        return string.concat(
            '<rect x="10" y="268" width="280" height="22" rx="4" fill="black" opacity="0.5"/>',
            '<text x="150" y="283" font-family="monospace" font-size="10" fill="white" text-anchor="middle">',
            '#', tokenId.toString(), ' \xc2\xb7 ', (amount / 1e18).toString(), ' $MEOW',
            '</text>'
        );
    }

    function totalMinted() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 total = _tokenIdCounter;
        uint256 count;
        for (uint256 i = 1; i <= total; i++) {
            if (_ownerOf(i) == _owner) count++;
        }

        uint256[] memory ids = new uint256[](count);
        uint256 idx;
        for (uint256 i = 1; i <= total; i++) {
            if (_ownerOf(i) == _owner) ids[idx++] = i;
        }

        return ids;
    }
}
