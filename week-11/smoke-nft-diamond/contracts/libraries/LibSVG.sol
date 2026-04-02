// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LibSVG
/// @notice A pure on-chain library for building SVG strings — specialised in
///         procedural smoke, ember and fire visuals derived from an address seed.
library LibSVG {
    // ─────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Convert uint to decimal string
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

    /// @dev Convert int to decimal string (handles negatives)
    function _int2str(int256 v) internal pure returns (string memory) {
        if (v >= 0) return _uint2str(uint256(v));
        return string(abi.encodePacked("-", _uint2str(uint256(-v))));
    }

    /// @dev Convert uint8 to 2-char hex
    function _byteToHex(uint8 b) internal pure returns (string memory) {
        bytes memory h = new bytes(2);
        uint8 hi = b >> 4;
        uint8 lo = b & 0x0f;
        h[0] = hi < 10 ? bytes1(48 + hi) : bytes1(87 + hi);
        h[1] = lo < 10 ? bytes1(48 + lo) : bytes1(87 + lo);
        return string(h);
    }

    /// @dev Build a hex color string from r,g,b
    function _rgb(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "#",
                    _byteToHex(r),
                    _byteToHex(g),
                    _byteToHex(b)
                )
            );
    }

    /// @dev Linear interpolate between two uint8 values
    function _lerp8(
        uint8 a,
        uint8 b,
        uint256 t,
        uint256 max
    ) internal pure returns (uint8) {
        if (t >= max) return b;
        return uint8(uint256(a) + ((uint256(b) - uint256(a)) * t) / max);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Seed helpers
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Extract an 8-bit value from a seed at byte position `idx`
    function _seedByte(uint256 seed, uint8 idx) internal pure returns (uint8) {
        return uint8((seed >> (idx * 8)) & 0xff);
    }

    /// @dev Map a seed byte into a range [lo, hi]
    function _range(
        uint8 b,
        uint256 lo,
        uint256 hi
    ) internal pure returns (uint256) {
        return lo + (uint256(b) * (hi - lo)) / 255;
    }

    struct PlumeData {
        int256 originX;
        int256 originY;
        int256 cp1x;
        int256 cp1y;
        int256 cp2x;
        int256 cp2y;
        int256 endX;
        int256 endY;
        int256 w;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Color palette derivation
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev SmokeStyle encodes all per-address visual decisions
    struct SmokeStyle {
        // Palette
        uint8 r0;
        uint8 g0;
        uint8 b0; // color stop 0
        uint8 r1;
        uint8 g1;
        uint8 b1; // color stop 1
        uint8 r2;
        uint8 g2;
        uint8 b2; // color stop 2 (fire tint / accent)
        // Layout
        bool fireMode; // true → dominant fire palette + ember sparks
        bool driftLeft; // direction of smoke drift
        bool swirl; // enable swirling turbulence
        uint8 plumeCount; // 2-6 main plume paths
        uint8 speed; // animation speed multiplier bucket (1-4)
        uint8 opacity; // base opacity bucket 60-90
        uint8 spread; // horizontal spread 20-70
        uint8 yOffset; // vertical offset of origin 200-380
        uint8 turbulence; // turbulence frequency 1-5 (×0.01)
        uint8 particleCount; // 4-12 background particles
        uint8 glowRadius; // glow filter radius 4-20
    }

    /// @notice Derive a SmokeStyle deterministically from a minter address seed
    function deriveStyle(
        address minter
    ) internal pure returns (SmokeStyle memory s) {
        uint256 seed = uint256(keccak256(abi.encodePacked(minter)));
        uint8 b0 = _seedByte(seed, 0);

        // Fire mode: top 1 bit of byte 0 AND byte 1 > 200
        s.fireMode = (b0 & 0x80) != 0 && _seedByte(seed, 1) > 180;

        if (s.fireMode) {
            // Fire palette: deep orange/red base, yellow top, white-blue core
            s.r0 = _lerp8(200, 255, _seedByte(seed, 2), 255);
            s.g0 = _lerp8(20, 90, _seedByte(seed, 3), 255);
            s.b0 = uint8(_range(_seedByte(seed, 4), 0, 30));

            s.r1 = 255;
            s.g1 = _lerp8(160, 220, _seedByte(seed, 5), 255);
            s.b1 = uint8(_range(_seedByte(seed, 6), 0, 60));

            s.r2 = _lerp8(220, 255, _seedByte(seed, 7), 255);
            s.g2 = _lerp8(240, 255, _seedByte(seed, 8), 255);
            s.b2 = _lerp8(100, 220, _seedByte(seed, 9), 255);
        } else {
            // Smoke palette: grey + chromatic tint
            uint8 base = _lerp8(40, 200, _seedByte(seed, 2), 255);
            uint8 tintR = _seedByte(seed, 10);
            uint8 tintG = _seedByte(seed, 11);
            uint8 tintB = _seedByte(seed, 12);
            uint8 tintStr = _lerp8(0, 60, _seedByte(seed, 13), 255);

            s.r0 = base > tintStr
                ? base - tintStr + (tintR > 127 ? tintStr : 0)
                : 0;
            s.g0 = base > tintStr
                ? base - tintStr + (tintG > 127 ? tintStr : 0)
                : 0;
            s.b0 = base > tintStr
                ? base - tintStr + (tintB > 127 ? tintStr : 0)
                : 0;

            s.r1 = _lerp8(s.r0, 230, _seedByte(seed, 14), 255);
            s.g1 = _lerp8(s.g0, 230, _seedByte(seed, 15), 255);
            s.b1 = _lerp8(s.b0, 230, _seedByte(seed, 16), 255);

            // accent: slight ember glow
            s.r2 = _lerp8(180, 255, _seedByte(seed, 17), 255);
            s.g2 = _lerp8(80, 160, _seedByte(seed, 18), 255);
            s.b2 = uint8(_range(_seedByte(seed, 19), 0, 80));
        }

        s.driftLeft = _seedByte(seed, 20) > 127;
        s.swirl = _seedByte(seed, 21) > 160;
        s.plumeCount = uint8(_range(_seedByte(seed, 22), 2, 6));
        s.speed = uint8(_range(_seedByte(seed, 23), 1, 4));
        s.opacity = uint8(_range(_seedByte(seed, 24), 60, 92));
        s.spread = uint8(_range(_seedByte(seed, 25), 22, 70));
        s.yOffset = uint8(_range(_seedByte(seed, 26), 200, 380));
        s.turbulence = uint8(_range(_seedByte(seed, 27), 1, 5));
        s.particleCount = uint8(_range(_seedByte(seed, 28), 4, 12));
        s.glowRadius = uint8(_range(_seedByte(seed, 29), 4, 20));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SVG element builders
    // ─────────────────────────────────────────────────────────────────────────

    function _defs(
        SmokeStyle memory s,
        uint256 seed
    ) internal pure returns (string memory) {
        string memory col0 = _rgb(s.r0, s.g0, s.b0);
        string memory col1 = _rgb(s.r1, s.g1, s.b1);
        string memory col2 = _rgb(s.r2, s.g2, s.b2);
        return string(abi.encodePacked(
            "<defs>",
            _sgGradient(col0, col1, s.opacity),
            _agGradient(col2, col0),
            _bgGradient(col0),
            _gfFilter(s.glowRadius),
            _sfFilter(s.turbulence, seed),
            s.swirl ? _swFilter(s.turbulence, seed) : "",
            "</defs>"
        ));
    }

    function _sgGradient(string memory col0, string memory col1, uint8 opacity) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<linearGradient id="sg" x1="0" y1="1" x2="0" y2="0">',
            '<stop offset="0%" stop-color="', col0, '" stop-opacity="', _uint2str(opacity), '%"/>',
            '<stop offset="55%" stop-color="', col1, '" stop-opacity="50%"/>',
            '<stop offset="100%" stop-color="', col1, '" stop-opacity="0%"/>',
            "</linearGradient>"
        ));
    }

    function _agGradient(string memory col2, string memory col0) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<radialGradient id="ag" cx="50%" cy="60%" r="50%">',
            '<stop offset="0%" stop-color="', col2, '" stop-opacity="80%"/>',
            '<stop offset="100%" stop-color="', col0, '" stop-opacity="0%"/>',
            "</radialGradient>"
        ));
    }

    function _bgGradient(string memory col0) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<radialGradient id="bg" cx="50%" cy="80%" r="45%">',
            '<stop offset="0%" stop-color="', col0, '" stop-opacity="35%"/>',
            '<stop offset="100%" stop-color="', col0, '" stop-opacity="0%"/>',
            "</radialGradient>"
        ));
    }

    function _gfFilter(uint8 glowR) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<filter id="gf" x="-50%" y="-50%" width="200%" height="200%">',
            '<feGaussianBlur stdDeviation="', _uint2str(glowR), '" result="blur"/>',
            '<feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>',
            "</filter>"
        ));
    }

    function _sfFilter(uint8 turb, uint256 seed) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<filter id="sf" x="-30%" y="-30%" width="160%" height="160%">',
            '<feTurbulence type="fractalNoise" baseFrequency="0.0', _uint2str(turb),
            ' 0.01" numOctaves="4" seed="', _uint2str(_seedByte(seed, 31)), '" result="noise"/>',
            '<feDisplacementMap in="SourceGraphic" in2="noise" scale="18" xChannelSelector="R" yChannelSelector="G"/>',
            "</filter>"
        ));
    }

    function _swFilter(uint8 turb, uint256 seed) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<filter id="sw"><feTurbulence type="turbulence" baseFrequency="0.0', _uint2str(turb),
            '" numOctaves="3" seed="', _uint2str(_seedByte(seed, 30)),
            '"/><feDisplacementMap in="SourceGraphic" scale="30" xChannelSelector="R" yChannelSelector="G"/></filter>'
        ));
    }

    function _background() internal pure returns (string memory) {
        return
            '<rect width="500" height="500" fill="#0a0a0e"/>'
            '<rect width="500" height="500" fill="url(#bg)"/>';
    }

    /// @dev Build a single cubic-bezier smoke plume path
    function _plumePath(
        SmokeStyle memory s,
        uint256 seed,
        uint8 idx
    ) internal pure returns (string memory) {
        return _buildPlumeFullPath(
            s.spread, s.yOffset, s.speed, s.driftLeft, seed, idx
        );
    }

    function _buildPlumeFullPath(
        uint8 spread,
        uint8 yOffset,
        uint8 speed,
        bool driftLeft,
        uint256 seed,
        uint8 idx
    ) internal pure returns (string memory) {
        string memory d = _buildPlumeData(seed, idx, spread, yOffset, driftLeft);
        uint256 dur = 3 + uint256(speed) + uint256(idx);
        string memory durStr = string(abi.encodePacked(_uint2str(dur), "s"));
        return _buildPlumeAnim(d, durStr, driftLeft);
    }

    function _buildPlumeData(
        uint256 seed,
        uint8 idx,
        uint8 spread,
        uint8 yOffset,
        bool driftLeft
    ) internal pure returns (string memory) {
        (int256 originX, int256 originY) = _computeOrigin(seed, idx, spread, yOffset);
        (int256 cp1x, int256 cp1y, int256 cp2x, int256 cp2y, int256 endX) = 
            _computeCurvePoints(seed, idx, originX, originY, driftLeft);
        (int256 endY, int256 w) = _computeEndAndWidth(seed, idx);
        return _buildPlumePath(originX, originY, cp1x, cp1y, cp2x, cp2y, endX, endY, w);
    }

    function _computeOrigin(
        uint256 seed,
        uint8 idx,
        uint8 spread,
        uint8 yOffset
    ) internal pure returns (int256 originX, int256 originY) {
        uint256 spreadHalf = uint256(spread);
        uint8 b0 = _seedByte(seed, 32 + idx * 4);
        originX = 250 + int256((uint256(b0) * spreadHalf * 2) / 255) - int256(spreadHalf);
        originY = int256(uint256(yOffset));
    }

    function _computeCurvePoints(
        uint256 seed,
        uint8 idx,
        int256 originX,
        int256 originY,
        bool driftLeft
    ) internal pure returns (int256 cp1x, int256 cp1y, int256 cp2x, int256 cp2y, int256 endX) {
        int256 dX = driftLeft
            ? -int256(_range(_seedByte(seed, 32 + idx * 4 + 1), 30, 90))
            : int256(_range(_seedByte(seed, 32 + idx * 4 + 1), 30, 90));

        cp1x = originX + dX / 3 + int256(_range(_seedByte(seed, 32 + idx * 4 + 2), 0, 40)) - 20;
        cp1y = originY - int256(_range(_seedByte(seed, 32 + idx * 4 + 3), 60, 130));

        cp2x = originX + (dX * 2) / 3 + int256(_range(_seedByte(seed, 40 + idx), 0, 60)) - 30;
        cp2y = cp1y - int256(_range(_seedByte(seed, 46 + idx), 60, 120));

        endX = originX + dX;
    }

    function _computeEndAndWidth(
        uint256 seed,
        uint8 idx
    ) internal pure returns (int256 endY, int256 w) {
        endY = int256(_range(_seedByte(seed, 52 + idx), 20, 80));
        w = int256(_range(_seedByte(seed, 58 + idx), 18, 55));
    }

    function _buildPlumeAnim(
        string memory d,
        string memory durStr,
        bool driftLeft
    ) internal pure returns (string memory) {
        string memory tx1 = _int2str(0);
        string memory tx2 = driftLeft ? _int2str(-8) : _int2str(8);

        return
            string(
                abi.encodePacked(
                    '<path d="',
                    d,
                    '" fill="url(#sg)" filter="url(#sf)" opacity="0.85">',
                    '<animateTransform attributeName="transform" type="translate"',
                    ' values="',
                    tx1,
                    ",0; ",
                    tx2,
                    ",-6; ",
                    tx1,
                    ',0"',
                    ' dur="',
                    durStr,
                    '" repeatCount="indefinite" calcMode="spline"',
                    ' keySplines="0.4 0 0.6 1; 0.4 0 0.6 1"/>',
                    '<animate attributeName="opacity" values="0;0.85;0.7;0.85;0" dur="',
                    durStr,
                    '" repeatCount="indefinite"/>',
                    "</path>"
                )
            );
    }

    function _computeOriginX(
        uint256 seed,
        uint8 idx,
        uint8 spread
    ) internal pure returns (int256) {
        uint256 spreadHalf = uint256(spread);
        uint8 b0 = _seedByte(seed, 32 + idx * 4);
        return
            250 +
            int256((uint256(b0) * spreadHalf * 2) / 255) -
            int256(spreadHalf);
    }

    function _computeCurvePoints(
        uint256 seed,
        uint8 idx,
        int256 originX,
        int256 originY,
        bool driftLeft,
        int256 cp1x,
        int256 cp1y,
        int256 cp2x,
        int256 cp2y,
        int256 endX
    ) internal pure {
        int256 dX = driftLeft
            ? -int256(_range(_seedByte(seed, 32 + idx * 4 + 1), 30, 90))
            : int256(_range(_seedByte(seed, 32 + idx * 4 + 1), 30, 90));

        cp1x = originX +
            dX /
            3 +
            int256(_range(_seedByte(seed, 32 + idx * 4 + 2), 0, 40)) -
            20;
        cp1y = originY -
            int256(_range(_seedByte(seed, 32 + idx * 4 + 3), 60, 130));

        cp2x = originX +
            (dX * 2) /
            3 +
            int256(_range(_seedByte(seed, 40 + idx), 0, 60)) -
            30;
        cp2y = cp1y - int256(_range(_seedByte(seed, 46 + idx), 60, 120));

        endX = originX + dX;
    }

    function _buildPlumePath(
        int256 originX,
        int256 originY,
        int256 cp1x,
        int256 cp1y,
        int256 cp2x,
        int256 cp2y,
        int256 endX,
        int256 endY,
        int256 w
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "M ", _int2str(originX - w / 2), " ", _int2str(originY),
            " C ", _int2str(cp1x - w / 2), " ", _int2str(cp1y),
            " ", _int2str(cp2x - w), " ", _int2str(cp2y),
            " ", _int2str(endX - w / 2), " ", _int2str(endY),
            " C ", _int2str(endX), " ", _int2str(endY - 10),
            " ", _int2str(cp2x + w), " ", _int2str(cp2y),
            " ", _int2str(cp1x + w / 2), " ", _int2str(cp1y),
            " C ", _int2str(originX + w / 2), " ", _int2str(originY + 5),
            " ", _int2str(originX + w / 2), " ", _int2str(originY),
            " ", _int2str(originX - w / 2), " ", _int2str(originY),
            " Z"
        ));
    }

    /// @dev Build fire tongue paths (fire mode only)
    function _fireTongue(
        SmokeStyle memory s,
        uint256 seed,
        uint8 idx
    ) internal pure returns (string memory) {
        int256 ox = _computeFireOriginX(seed, idx, s.spread);
        int256 oy = int256(uint256(s.yOffset)) + 20;
        int256 height = int256(_range(_seedByte(seed, 70 + idx), 60, 160));
        int256 w = int256(_range(_seedByte(seed, 76 + idx), 10, 35));

        string memory dur = string(
            abi.encodePacked(
                _uint2str(1 + uint256(idx % 3)),
                ".",
                _uint2str(_seedByte(seed, 80 + idx) % 9),
                "s"
            )
        );

        string memory d = _buildFireTonguePath(ox, oy, height, w);

        return
            string(
                abi.encodePacked(
                    '<path d="',
                    d,
                    '" fill="url(#ag)" filter="url(#gf)">',
                    '<animate attributeName="opacity" values="0.9;0.6;1;0.7;0.9" dur="',
                    dur,
                    '" repeatCount="indefinite"/>',
                    '<animateTransform attributeName="transform" type="skewX"',
                    ' values="0;3;-3;2;0" dur="',
                    dur,
                    '" repeatCount="indefinite"/>',
                    "</path>"
                )
            );
    }

    function _computeFireOriginX(
        uint256 seed,
        uint8 idx,
        uint8 spread
    ) internal pure returns (int256) {
        int256 spreadI = int256(uint256(spread));
        int256 off = int256(
            (uint256(_seedByte(seed, 64 + idx)) * uint256(spread) * 2) / 255
        ) - spreadI;
        return 250 + off;
    }

    function _buildFireTonguePath(
        int256 ox,
        int256 oy,
        int256 height,
        int256 w
    ) internal pure returns (string memory) {
        int256 negW = -w;
        int256 halfH = height / 2;
        int256 halfW = w / 2;
        int256 threeQuartersH = (height * 3) / 4;
        int256 oxPlusW = ox + w;
        int256 oxMinusW = ox + negW;
        int256 oxMinusHalfW = ox + negW / 2;
        int256 oyMinusH = oy - height;
        int256 oyMinusHalfH = oy - halfH;
        int256 oyMinusThreeQuartersH = oy - threeQuartersH;

        return
            string(
                abi.encodePacked(
                    "M ",
                    _int2str(ox),
                    " ",
                    _int2str(oy),
                    " C ",
                    _int2str(oxMinusW),
                    " ",
                    _int2str(oyMinusHalfH),
                    " ",
                    _int2str(oxMinusHalfW),
                    " ",
                    _int2str(oyMinusThreeQuartersH),
                    " ",
                    _int2str(ox),
                    " ",
                    _int2str(oyMinusH),
                    " C ",
                    _int2str(ox + halfW),
                    " ",
                    _int2str(oyMinusThreeQuartersH),
                    " ",
                    _int2str(oxPlusW),
                    " ",
                    _int2str(oyMinusHalfH),
                    " ",
                    _int2str(ox),
                    " ",
                    _int2str(oy),
                    " Z"
                )
            );
    }

    /// @dev Floating ember / particle dots
    function _particles(
        SmokeStyle memory s,
        uint256 seed
    ) internal pure returns (string memory) {
        string memory out;
        string memory col2 = _rgb(s.r2, s.g2, s.b2);
        bool driftLeft = s.driftLeft;

        for (uint8 i = 0; i < s.particleCount; i++) {
            out = string(abi.encodePacked(out, _particleCircle(seed, i, col2, driftLeft, s.yOffset)));
        }
        return out;
    }

    function _particleCircle(
        uint256 seed,
        uint8 i,
        string memory col2,
        bool driftLeft,
        uint8 yOffset
    ) internal pure returns (string memory) {
        uint256 px = _range(_seedByte(seed, 84 + i), 150, 350);
        uint256 py = _range(_seedByte(seed, 96 + i), 80, uint256(yOffset));
        uint256 r = _range(_seedByte(seed, 108 + i), 1, 4);
        uint256 dur = 2 + _range(_seedByte(seed, 120 + i), 1, 4);
        int256 driftX = driftLeft
            ? -int256(_range(_seedByte(seed, 132 + i), 10, 40))
            : int256(_range(_seedByte(seed, 132 + i), 10, 40));

        return string(abi.encodePacked(
            '<circle cx="', _uint2str(px), '" cy="', _uint2str(py), '" r="', _uint2str(r), '" fill="', col2, '" opacity="0.7" filter="url(#gf)">',
            '<animate attributeName="cy" values="', _uint2str(py), ";", _uint2str(py > 40 ? py - 40 : 0), ";", _uint2str(py), '"', ' dur="', _uint2str(dur), 's" repeatCount="indefinite"/>',
            '<animate attributeName="cx" values="', _uint2str(px), ";", _int2str(int256(px) + driftX), ";", _uint2str(px), '"', ' dur="', _uint2str(dur), 's" repeatCount="indefinite"/>',
            '<animate attributeName="opacity" values="0;0.8;0" dur="', _uint2str(dur), 's" repeatCount="indefinite"/>',
            "</circle>"
        ));
    }

    /// @dev Source label at the bottom
    function _label(
        address minter,
        bool fireMode
    ) internal pure returns (string memory) {
        string memory modeStr = fireMode ? "FIRE" : "SMOKE";
        // Abbreviate address: 0x1234...abcd
        bytes memory a = abi.encodePacked(minter);
        string memory addrShort = string(
            abi.encodePacked(
                "0x",
                _byteToHex(uint8(a[0])),
                _byteToHex(uint8(a[1])),
                _byteToHex(uint8(a[2])),
                "...",
                _byteToHex(uint8(a[19]))
            )
        );

        return
            string(
                abi.encodePacked(
                    '<text x="250" y="478" font-family="monospace" font-size="9" fill="#ffffff44"',
                    ' text-anchor="middle">',
                    modeStr,
                    " \u2022 ",
                    addrShort,
                    "</text>"
                )
            );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Primary entry point
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Generate a complete SVG for the given minter address
    /// @param  minter The address whose seed drives all visual parameters
    /// @return svg    The full SVG string (500×500, self-contained, animated)
    function generateSVG(
        address minter
    ) internal pure returns (string memory svg) {
        SmokeStyle memory s = deriveStyle(minter);
        uint256 seed = uint256(keccak256(abi.encodePacked(minter)));

        // Plumes
        string memory plumes;
        for (uint8 i = 0; i < s.plumeCount; i++) {
            plumes = string(abi.encodePacked(plumes, _plumePath(s, seed, i)));
        }

        // Fire tongues (only in fire mode)
        string memory tongues;
        if (s.fireMode) {
            uint8 tongueCount = s.plumeCount > 2
                ? s.plumeCount - 1
                : s.plumeCount;
            for (uint8 i = 0; i < tongueCount; i++) {
                tongues = string(
                    abi.encodePacked(tongues, _fireTongue(s, seed, i))
                );
            }
        }

        svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500" width="500" height="500">',
                _defs(s, seed),
                _background(),
                s.fireMode ? tongues : "", // fire under smoke
                plumes,
                s.fireMode ? "" : tongues, // no tongues in pure smoke — placeholder
                _particles(s, seed),
                _label(minter, s.fireMode),
                "</svg>"
            )
        );
    }

    /// @notice Generate only the style descriptor (useful for off-chain previews)
    function describeStyle(
        address minter
    )
        internal
        pure
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
        SmokeStyle memory s = deriveStyle(minter);
        fireMode = s.fireMode;
        driftLeft = s.driftLeft;
        swirl = s.swirl;
        plumeCount = s.plumeCount;
        colorA = _rgb(s.r0, s.g0, s.b0);
        colorB = _rgb(s.r1, s.g1, s.b1);
        colorAccent = _rgb(s.r2, s.g2, s.b2);
    }
}
