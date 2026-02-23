// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Prom is Ownable {
    // ================= Data Structures =================

    enum UserType {
        Regular,
        Investor,
        Developer
    }

    struct PropertyOwner {
        address ownerAddress;
        uint256[] ownedProperties;
        string name;
        string occupation;
        UserType userType;
        bool isVerified;
        uint40 verifiedAt;
        bool isActive;
        uint40 createdAt;
        uint40 lastActiveAt;
    }

    struct Coords {
        uint256 x;
        uint256 y;
    }

    struct PropertyMetadata {
        string description;
        string imageUrl;
        string landmark;
    }

    struct Property {
        string name;
        uint256 price;
        address owner;
        Coords coordinates;
        bool forSale;
        uint40 forSaleSince;
        PropertyMetadata metadata;
        bool isDeleted;
        uint40 deletedAt;
        uint40 createdAt;
        uint40 modifiedAt;
    }

    // ================= Events =================

    event PropertyOwnerRegistered(address indexed ownerAddress, string name, string occupation, UserType userType);
    event PropertyOwnerVerified(address indexed ownerAddress, uint40 verifiedAt);
    event PropertyOwnerDeactivated(address indexed ownerAddress, uint40 deactivatedAt);
    event PropertyOwnerReactivated(address indexed ownerAddress, uint40 reactivatedAt);
    event PropertyOwnerAlreadyRegistered(address indexed ownerAddress);
    event PropertyOwnershipTransferred(uint256 indexed propertyId, address indexed from, address indexed to);
    event PropertyListed(uint256 indexed propertyId, uint256 price);
    event PropertyDelisted(uint256 indexed propertyId);
    event PropertyOutForSale(uint256 indexed propertyId, uint256 price);
    event PropertyPriceUpdated(uint256 indexed propertyId, uint256 newPrice);
    event PropertyPurchased(uint256 indexed propertyId, address indexed buyer, uint256 price);

    // ================= Error Definitions =================

    error PropertyNotFound(uint256 propertyId);
    error NotPropertyOwner(uint256 propertyId);
    error PropertyNotForSale(uint256 propertyId);
    event InsufficientPayment(uint256 propertyId, uint256 sent, uint256 required);

    // ================= State Variables =================

    bytes4 private _name;
    address private _owner;
    IERC20 private immutable _paymentToken;
    mapping(address => PropertyOwner) _propertyOwners;
    mapping(uint256 => Property) private _properties;
    uint256 private _propertyCount;

    // ================= Modifiers =================

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }

    modifier exceptOwner() {
        require(msg.sender != _owner, "Contract owner cannot call this function");
        _;
    }

    modifier onlyVerifiedOwners() {
        PropertyOwner memory owner = _propertyOwners[msg.sender];
        require(owner.ownerAddress != address(0), "Property owner not found");
        require(owner.isVerified, "Property owner is not verified");
        require(owner.isActive, "Property owner is not active");
        _;
    }

    modifier onlyPropertyOwner(uint256 propertyId) {
        if (_properties[propertyId].owner != msg.sender) {
            revert NotPropertyOwner(propertyId);
        }
        _;
    }

    modifier propertyExists(uint256 propertyId) {
        if (_properties[propertyId].owner == address(0)) {
            revert PropertyNotFound(propertyId);
        }
        _;
    }

    constructor(address _tokenAddress) {
        _owner = msg.sender;
        _paymentToken = IERC20(_tokenAddress);
        _name = bytes4(keccak256("Prom"));
    }

    // ================= Private/Internal Functions =================

    function _generatePropertyId() private returns (uint256) {
        return ++_propertyCount;
    }

    // ================= Public/External Functions =================

    function name() external view returns (bytes4) {
        return _name;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function paymentToken() external view returns (address) {
        return address(_paymentToken);
    }

    function getPropertyOwner(address _ownerAddress) external view returns (PropertyOwner memory) {
        return _propertyOwners[_ownerAddress];
    }

    function getProperty(uint256 _propertyId) external view propertyExists(_propertyId) returns (Property memory) {
        return _properties[_propertyId];
    }

    function countAccountProperties(address _ownerAddress) external view returns (uint256) {
        return _propertyOwners[_ownerAddress].ownedProperties.length;
    }

    function totalProperties() external view returns (uint256) {
        return _propertyCount;
    }

    function setName(string memory _newName, string memory _prevName) external onlyOwner {
        require(bytes(_newName).length == 4, "Name must be 4 characters");
        require(keccak256(_prevName) == _name, "Previous name does not match");
        require(keccak256(_newName) != _name, "New name must be different");

        _name = bytes4(keccak256(_newName));
    }

    function registerPropertyOwner(
        string memory _name,
        string memory _occupation,
        UserType _userType
    ) external exceptOwner {
        if (_propertyOwners[msg.sender].ownerAddress != address(0)) {
            revert PropertyOwnerAlreadyRegistered(msg.sender);
        }

        _propertyOwners[msg.sender] = PropertyOwner({
            ownerAddress: msg.sender,
            ownedProperties: new uint256[](0),
            name: _name,
            occupation: _occupation,
            userType: _userType,
            isVerified: false,
            verifiedAt: 0,
            isActive: true,
            createdAt: uint40(block.timestamp),
            lastActiveAt: uint40(block.timestamp)
        });

        emit PropertyOwnerRegistered(msg.sender, _name, _occupation, _userType);
    }

    function verifyPropertyOwner(address _ownerAddress) external exceptOwner payable {
        require(msg.value >= 0.0054 ether, "Verification requires a fee of 0.0054 ETH (approx. $10)");

        PropertyOwner storage owner = _propertyOwners[_ownerAddress];
        require(owner.ownerAddress != address(0), "Property owner not found");

        if (owner.isVerified) {
            // Penalize 20% of the fee for already verified owners
            uint256 penalty = (msg.value * 20) / 100;
            uint256 refundAmount = msg.value - penalty;
            if (refundAmount > 0) {
                payable(msg.sender).transfer(refundAmount);
            }

            revert PropertyOwnerAlreadyRegistered(msg.sender);
        } else {
            owner.isVerified = true;
            owner.verifiedAt = uint40(block.timestamp);
            emit PropertyOwnerVerified(msg.sender, owner.verifiedAt);
        }
    }

    function deactivatePropertyOwner(address _ownerAddress) external onlyOwner {
        PropertyOwner storage owner = _propertyOwners[_ownerAddress];

        require(owner.ownerAddress != address(0), "Property owner not found");
        require(owner.isActive, "Property owner is already deactivated");

        owner.isActive = false;
        owner.lastActiveAt = uint40(block.timestamp);

        emit PropertyOwnerDeactivated(_ownerAddress, owner.lastActiveAt);
    }

    function reactivatePropertyOwner(address _ownerAddress) external onlyOwner {
        PropertyOwner storage owner = _propertyOwners[_ownerAddress];

        require(owner.ownerAddress != address(0), "Property owner not found");
        require(!owner.isActive, "Property owner is already active");

        owner.isActive = true;
        owner.lastActiveAt = uint40(block.timestamp);

        emit PropertyOwnerReactivated(_ownerAddress, owner.lastActiveAt);
    }

    function listProperty(
        string memory _name,
        uint256 _price,
        Coords memory _coordinates,
        PropertyMetadata memory _metadata
    ) external onlyVerifiedOwners payable {
        require(_price > 0, "Price must be greater than zero");
        require(bytes(_name).length > 0, "Property name cannot be empty");

        uint256 propertyId = _generatePropertyId();

        _properties[propertyId] = Property({
            name: _name,
            price: _price,
            owner: msg.sender,
            coordinates: _coordinates,
            forSale: false,
            forSaleSince: 0,
            metadata: _metadata,
            isDeleted: false,
            deletedAt: 0,
            createdAt: uint40(block.timestamp),
            modifiedAt: uint40(block.timestamp)
        });

        uint256[] memory ownedProperties = _propertyOwners[msg.sender].ownedProperties;
        if (ownedProperties.length % 10 == 0) {
            require(msg.value >= 0.0011 ether, "Listing every 10 properties requires a fee of 0.0011 ETH (approx. $2)");
        }
        
        _propertyOwners[msg.sender].ownedProperties.push(propertyId);
        emit PropertyListed(propertyId, _price);
    }

    function delistProperty(uint256 _propertyId) external onlyVerifiedOwners onlyPropertyOwner(_propertyId) {
        Property storage property = _properties[_propertyId];

        require(property.forSale, "Property is not currently for sale");
        
        property.forSale = false;
        property.forSaleSince = 0;
        property.modifiedAt = uint40(block.timestamp);

        emit PropertyDelisted(_propertyId);
    }

    function putPropertyForSale(uint256 _propertyId, uint256 _price) external onlyVerifiedOwners onlyPropertyOwner(_propertyId) {
        Property storage property = _properties[_propertyId];

        require(!property.forSale, "Property is already for sale");
        require(_price > 0, "Price must be greater than zero");

        property.forSale = true;
        property.forSaleSince = uint40(block.timestamp);
        property.price = _price;
        property.modifiedAt = uint40(block.timestamp);

        emit PropertyOutForSale(_propertyId, _price);
    }

    function updatePropertyPrice(
        uint256 _propertyId,
        uint256 _newPrice
    ) external onlyVerifiedOwners onlyPropertyOwner(_propertyId) {
        Property storage property = _properties[_propertyId];

        require(property.forSale, "Property must be for sale to update price");
        require(_newPrice > 0, "New price must be greater than zero");

        property.price = _newPrice;
        property.modifiedAt = uint40(block.timestamp);

        emit PropertyPriceUpdated(_propertyId, _newPrice);
    }

    function purchaseProperty(uint256 _propertyId) external onlyVerifiedOwners propertyExists(_propertyId) {
        Property storage property = _properties[_propertyId];

        require(property.forSale, "Property is not for sale");
        require(property.owner != msg.sender, "Cannot purchase your own property");

        uint256 buyerBalance = _paymentToken.balanceOf(msg.sender);
        if (buyerBalance < property.price) {
            revert InsufficientPayment(_propertyId, buyerBalance, property.price);
        }

        _paymentToken.transferFrom(msg.sender, property.owner, property.price);
        address previousOwner = property.owner;
        property.owner = msg.sender;

        // Update ownership records
        uint256[] storage previousProperties = _propertyOwners[previousOwner].ownedProperties;
        uint256 propertiesCount = previousProperties.length;
        for (uint256 i = 0; i < previousProperties.length; i++) {
            if (previousProperties[i] == _propertyId) {
                previousProperties[i] = previousProperties[propertiesCount - 1];
                previousProperties.pop();
                break;
            }
        }

        _propertyOwners[msg.sender].ownedProperties.push(_propertyId);

        property.forSale = false;
        property.forSaleSince = 0;
        property.modifiedAt = uint40(block.timestamp);

        emit PropertyPurchased(_propertyId, msg.sender, property.price);
        emit PropertyOwnershipTransferred(_propertyId, previousOwner, msg.sender);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient contract balance");

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
    }
}
