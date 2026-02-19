// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface ITokenManager {
    event TokenSupported(address indexed _tokenAddress, string _tokenSymbol, uint8 _tokenDecimals);
    event TokenRemoved(address indexed _tokenAddress);

    function addSupportedToken(address _tokenAddress, string memory _tokenSymbol, uint8 _tokenDecimals) external;
    function removeSupportedToken(address _tokenAddress) external;
    function isTokenSupported(address _tokenAddress) external view returns (bool);
    function getSupportedTokens() external view returns (address[] memory);
}
