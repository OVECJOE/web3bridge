// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

library SVGLib {
    function sissyGenerateTokenURI(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _tokenAddr,
        address _vaultAddr,
        uint256 _totalLiquidity,
        uint8 _decimals
    ) internal pure returns (string memory) {
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350">',
            '<rect width="100%" height="100%" fill="#1a1a2e"/>',
            '<text x="175" y="60" text-anchor="middle">',
            _tokenSymbol,
            " Vault</text>",
            '<text x="175" y="100" text-anchor="middle">',
            _tokenName,
            "</text>",
            '<text x="175" y="140" text-anchor="middle">',
            "Total Liquidity: ",
            Strings.toString(_totalLiquidity),
            "</text>",
            '<text x="175" y="180" text-anchor="middle">',
            "Token Address: ",
            Strings.toHexString(_tokenAddr),
            "</text>",
            '<text x="175" y="220" text-anchor="middle">',
            "Vault Address: ",
            Strings.toHexString(_vaultAddr),
            "</text>",
            '<text x="175" y="260" text-anchor="middle">',
            "Decimals: ",
            Strings.toString(uint256(_decimals)),
            "</text>",
            "</svg>"
        );

        string memory json = string.concat(
            '{"name": "',
            _tokenName,
            '", "description": "',
            _tokenSymbol,
            ' Vault", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            );
    }

    function qrCodeGenerateTokenURI(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _tokenAddr,
        address _vaultAddr,
        uint256 _totalLiquidity,
        uint8 _decimals
    ) internal pure returns (string memory) {
        // Derive a deterministic seed from all inputs
        bytes32 seed = keccak256(
            abi.encodePacked(_tokenAddr, _vaultAddr, _totalLiquidity, _decimals)
        );

        // Extract hues (0-359) and geometry values from seed bytes
        uint256 hue1 = (uint256(uint8(seed[0])) * 360) / 255;
        uint256 hue2 = (uint256(uint8(seed[1])) * 360) / 255;
        uint256 hue3 = (uint256(uint8(seed[2])) * 360) / 255;
        uint256 hue4 = (uint256(uint8(seed[3])) * 360) / 255;

        // Background: dark desaturated version of hue1
        string memory bgColor = string.concat(
            "hsl(",
            Strings.toString(hue1),
            ",20%,10%)"
        );

        // Build 4 generative blobs from seed geometry
        string memory blobs = string.concat(
            _blob(
                50 + (uint256(uint8(seed[4])) % 200),
                50 + (uint256(uint8(seed[5])) % 200),
                60 + (uint256(uint8(seed[6])) % 80),
                hue1
            ),
            _blob(
                50 + (uint256(uint8(seed[7])) % 200),
                50 + (uint256(uint8(seed[8])) % 200),
                50 + (uint256(uint8(seed[9])) % 70),
                hue2
            ),
            _blob(
                50 + (uint256(uint8(seed[10])) % 200),
                50 + (uint256(uint8(seed[11])) % 200),
                40 + (uint256(uint8(seed[12])) % 60),
                hue3
            ),
            _blob(
                50 + (uint256(uint8(seed[13])) % 200),
                50 + (uint256(uint8(seed[14])) % 200),
                45 + (uint256(uint8(seed[15])) % 65),
                hue4
            )
        );

        string memory explorerUrl = string.concat(
            "https://etherscan.io/address/",
            Strings.toHexString(_vaultAddr)
        );

        string memory qrSrc = string.concat(
            "https://api.qrserver.com/v1/create-qr-code/?size=150x150&amp;bgcolor=ffffff&amp;color=000000&amp;data=",
            explorerUrl
        );

        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350">',
            // Seed-derived dark background
            '<rect width="100%" height="100%" fill="',
            bgColor,
            '"/>',
            // Generative blob layer
            blobs,
            // White backing card for QR readability
            '<rect x="88" y="88" width="174" height="174" rx="12" fill="white" opacity="0.95"/>',
            // QR code centred on card
            '<image x="100" y="100" width="150" height="150" href="',
            qrSrc,
            '"/>',
            // Token label beneath
            '<text x="175" y="310" text-anchor="middle" font-family="monospace" font-size="13" fill="white" opacity="0.85">',
            _tokenSymbol,
            " Vault</text>",
            "</svg>"
        );

        string memory json = string.concat(
            '{"name": "Tault: ',
            _tokenName,
            ' Vault", "description": "A Tault vault for ',
            _tokenSymbol,
            '", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            );
    }

    /// @dev Renders a single semi-transparent blob circle
    function _blob(
        uint256 cx,
        uint256 cy,
        uint256 r,
        uint256 hue
    ) private pure returns (string memory) {
        return
            string.concat(
                '<circle cx="',
                Strings.toString(cx),
                '" cy="',
                Strings.toString(cy),
                '" r="',
                Strings.toString(r),
                '" fill="hsl(',
                Strings.toString(hue),
                ',65%,55%)" opacity="0.35"/>'
            );
    }
}
