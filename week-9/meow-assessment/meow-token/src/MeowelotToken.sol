// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MeowelotNFT} from "./MeowelotNFT.sol";

contract MeowelotToken is ERC20, ERC20Pausable, Ownable {
    error ExceedsMaxSupply();
    error CooldownNotElapsed(uint256 retryAt);
    error ExceedsAntiWhaleCap();
    error ZeroAddress();
    error Blacklisted();
    error TaxTooHigh();

    uint256 public constant MAX_SUPPLY = 10_000_000 * 1e18;
    uint256 public constant FAUCET_AMOUNT = 1_000 * 1e18;
    uint256 public constant FAUCET_COOLDOWN = 24 hours;
    uint256 public constant ANTI_WHALE_CAP = 200_000 * 1e18; // 2% of max supply
    uint256 public constant NFT_THRESHOLD = 10_000 * 1e18;

    // Fee basis points (100 = 1%)
    uint256 public burnFeeBps = 100; // 1% burned
    uint256 public treasuryFeeBps = 50; // 0.5% to treasury
    uint256 public extraBurnBps = 50; // 0.5% extra burned (tax split)

    address public treasuryAddress;
    MeowelotNFT public nftContract;
    mapping(address => uint256) public lastRequestTime;
    mapping(address => bool) private _hasRequested;
    mapping(address => bool) public blacklisted;
    uint256 public totalBurned;

    event TokensRequested(address indexed user, uint256 amount);
    event Minted(address indexed to, uint256 amount);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event NFTContractUpdated(address indexed oldNFT, address indexed newNFT);
    event FeesUpdated(uint256 burnBps, uint256 treasuryBps, uint256 extraBurnBps);

    constructor(address _initialOwner, address _treasury, address _nftContract) ERC20("Meowelot", "MEOW") Ownable(_initialOwner) {
        if (_treasury == address(0)) revert ZeroAddress();
        treasuryAddress = _treasury;
        nftContract = MeowelotNFT(_nftContract);

        // Mint initial supply to owner (50% of max)
        _mint(_initialOwner, 5_000_000 * 1e18);
    }

    /// @notice Claim 1,000 $MEOW every 24 hours. Anyone can call.
    function requestToken() external whenNotPaused {
        if (blacklisted[msg.sender]) revert Blacklisted();

        uint256 lastRequest = lastRequestTime[msg.sender];
        if (_hasRequested[msg.sender]) {
            uint256 nextAllowed = lastRequest + FAUCET_COOLDOWN;
            // Cooldown is inclusive: requesting exactly at boundary still reverts.
            if (block.timestamp <= nextAllowed) revert CooldownNotElapsed(nextAllowed + 1);
        }

        uint256 newSupply = totalSupply() + FAUCET_AMOUNT;
        if (newSupply > MAX_SUPPLY) revert ExceedsMaxSupply();

        // Anti-whale: faucet respects cap too
        if (balanceOf(msg.sender) + FAUCET_AMOUNT > ANTI_WHALE_CAP) revert ExceedsAntiWhaleCap();

        lastRequestTime[msg.sender] = block.timestamp;
        _hasRequested[msg.sender] = true;
        _mint(msg.sender, FAUCET_AMOUNT);

        emit TokensRequested(msg.sender, FAUCET_AMOUNT);
    }

    /// @notice Returns seconds until `user` can request again. 0 means available now.
    function timeUntilNextRequest(address _user) external view returns (uint256) {
        if (!_hasRequested[_user]) return 0;

        uint256 lastRequest = lastRequestTime[_user];

        uint256 nextAllowed = lastRequest + FAUCET_COOLDOWN;
        if (block.timestamp > nextAllowed) return 0;
        return (nextAllowed + 1) - block.timestamp;
    }

    /// @notice Owner can mint any amount up to MAX_SUPPLY.
    function mint(address _to, uint256 _amount) external onlyOwner whenNotPaused {
        if (_to == address(0)) revert ZeroAddress();
        if (totalSupply() + _amount > MAX_SUPPLY) revert ExceedsMaxSupply();
        _mint(_to, _amount);
        emit Minted(_to, _amount);
    }

    function _update(address _from, address _to, uint256 _value) internal override(ERC20, ERC20Pausable) {
        // Skip fees for mint/burn and owner
        if (_from == address(0) || _to == address(0) || _from == owner() || _to == owner()) {
            super._update(_from, _to, _value);
            return;
        }

        if (blacklisted[_from] || blacklisted[_to]) revert Blacklisted();

        // Calculate fees
        uint256 burnAmount = (_value * burnFeeBps) / 10_000;
        uint256 treasuryAmount = (_value * treasuryFeeBps) / 10_000;
        uint256 extraBurn = (_value * extraBurnBps) / 10_000;
        uint256 totalFee = burnAmount + treasuryAmount + extraBurn;
        uint256 netAmount = _value - totalFee;

        // Anti-whale: check on recipient
        if (balanceOf(_to) + netAmount > ANTI_WHALE_CAP) revert ExceedsAntiWhaleCap();

        // Execute transfers
        super._update(_from, _to, netAmount);
        super._update(_from, address(0), burnAmount + extraBurn); // burn
        super._update(_from, treasuryAddress, treasuryAmount); // treasury tax

        totalBurned += burnAmount + extraBurn;

        // NFT reward for big transfers
        if (_value >= NFT_THRESHOLD && address(nftContract) != address(0)) {
            uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _from, _to, _value, totalBurned)));
            try nftContract.mintOcelot(_to, _value, seed) {} catch {}
        }
    }

    // Admin

    function setBlacklist(address _user, bool _blacklisted) external onlyOwner {
        blacklisted[_user] = _blacklisted;
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        emit TreasuryUpdated(treasuryAddress, _treasury);
        treasuryAddress = _treasury;
    }

    function setNFTContract(address _nft) external onlyOwner {
        emit NFTContractUpdated(address(nftContract), _nft);
        nftContract = MeowelotNFT(_nft);
    }

    function setFees(uint256 _burnBps, uint256 _treasuryBps, uint256 _extraBurnBps) external onlyOwner {
        if (_burnBps + _treasuryBps + _extraBurnBps > 1000) revert TaxTooHigh(); // Max 10%
        burnFeeBps = _burnBps;
        treasuryFeeBps = _treasuryBps;
        extraBurnBps = _extraBurnBps;
        emit FeesUpdated(_burnBps, _treasuryBps, _extraBurnBps);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // Views

    function circulatingSupply() external view returns (uint256) {
        return totalSupply();
    }

    function remainingMintable() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }
}
