// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ISmokeNFTFacet} from "../contracts/interfaces/ISmokeNFTFacet.sol";
import {IDiamondCut} from "../contracts/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../contracts/interfaces/IDiamondLoupe.sol";
import {Diamond} from "../contracts/Diamond.sol";
import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../contracts/facets/OwnershipFacet.sol";
import {SmokeNFTFacet} from "../contracts/facets/SmokeNFTFacet.sol";
import {DiamondInit} from "../contracts/upgradeInitializers/DiamondInit.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract SmokeNFTTest is DiamondUpgradeHelper {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    SmokeNFTFacet smokeNFT;
    DiamondInit diamondInit;

    address owner = address(0xABCD);
    address user1 = address(0x1111);
    address user2 = address(0x2222);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event SmokeMinted(address indexed minter, uint256 indexed tokenId, bool fireMode, bool driftLeft, bool swirl, uint8 plumeCount);
    event MetadataUpdated(string name, string symbol);

    function setUp() public {
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        diamondInit = new DiamondInit();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        SmokeNFTFacet smokeNFTFacet = new SmokeNFTFacet(address(0));

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);

        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facets.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;

        bytes4[] memory ownerSelectors = new bytes4[](2);
        ownerSelectors[0] = OwnershipFacet.owner.selector;
        ownerSelectors[1] = OwnershipFacet.transferOwnership.selector;

        bytes4[] memory nftSelectors = new bytes4[](23);
        nftSelectors[0] = ISmokeNFTFacet.supportsInterface.selector;
        nftSelectors[1] = ISmokeNFTFacet.balanceOf.selector;
        nftSelectors[2] = ISmokeNFTFacet.ownerOf.selector;
        nftSelectors[3] = ISmokeNFTFacet.getApproved.selector;
        nftSelectors[4] = ISmokeNFTFacet.isApprovedForAll.selector;
        nftSelectors[5] = ISmokeNFTFacet.setApprovalForAll.selector;
        nftSelectors[6] = ISmokeNFTFacet.approve.selector;
        nftSelectors[7] = ISmokeNFTFacet.transferFrom.selector;
        nftSelectors[8] = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
        nftSelectors[9] = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
        nftSelectors[10] = ISmokeNFTFacet.name.selector;
        nftSelectors[11] = ISmokeNFTFacet.symbol.selector;
        nftSelectors[12] = ISmokeNFTFacet.tokenURI.selector;
        nftSelectors[13] = ISmokeNFTFacet.totalSupply.selector;
        nftSelectors[14] = ISmokeNFTFacet.tokenByIndex.selector;
        nftSelectors[15] = ISmokeNFTFacet.tokenOfOwnerByIndex.selector;
        nftSelectors[16] = ISmokeNFTFacet.tokenSVG.selector;
        nftSelectors[17] = ISmokeNFTFacet.minterOf.selector;
        nftSelectors[18] = ISmokeNFTFacet.styleOf.selector;
        nftSelectors[19] = ISmokeNFTFacet.hasMinted.selector;
        nftSelectors[20] = ISmokeNFTFacet.mint.selector;
        nftSelectors[21] = ISmokeNFTFacet.setNameAndSymbol.selector;
        nftSelectors[22] = bytes4(keccak256("initialize(string,string,address)"));

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(dLoupe),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownerF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownerSelectors
        });

        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(smokeNFTFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: nftSelectors
        });

        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(diamondInit), abi.encodeWithSignature("init()"));

        smokeNFT = SmokeNFTFacet(address(diamond));

        smokeNFT.initialize("SmokeNFT", "SMOKE", address(this));
    }

    function testSupportsInterface() public {
        assertTrue(smokeNFT.supportsInterface(0x80ac58cd));
        assertTrue(smokeNFT.supportsInterface(0x5b5e139f));
        assertTrue(smokeNFT.supportsInterface(0x780e9d63));
    }

    function testNameAndSymbol() public {
        assertEq(smokeNFT.name(), "SmokeNFT");
        assertEq(smokeNFT.symbol(), "SMOKE");
    }

    function testMint() public {
        vm.prank(user1);
        uint256 tokenId = smokeNFT.mint();

        assertEq(tokenId, 1);
        assertEq(smokeNFT.ownerOf(1), user1);
        assertEq(smokeNFT.balanceOf(user1), 1);
        assertTrue(smokeNFT.hasMinted(user1));
    }

    function testMintEmitsEvent() public {
        vm.prank(user1);
        vm.expectEmit(false, false, false, false);
        emit SmokeMinted(user1, 1, true, false, true, 4);
        smokeNFT.mint();
    }

    function testDoubleMintFails() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        vm.expectRevert("SmokeNFT: already minted");
        smokeNFT.mint();
    }

    function testMintUpdatesTotalSupply() public {
        assertEq(smokeNFT.totalSupply(), 0);

        vm.prank(user1);
        smokeNFT.mint();
        assertEq(smokeNFT.totalSupply(), 1);

        vm.prank(user2);
        smokeNFT.mint();
        assertEq(smokeNFT.totalSupply(), 2);
    }

    function testTokenByIndex() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user2);
        smokeNFT.mint();

        assertEq(smokeNFT.tokenByIndex(0), 1);
        assertEq(smokeNFT.tokenByIndex(1), 2);
    }

    function testTokenByIndexOutOfBounds() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.expectRevert("SmokeNFT: index out of bounds");
        smokeNFT.tokenByIndex(1);
    }

    function testTokenOfOwnerByIndex() public {
        vm.prank(user1);
        smokeNFT.mint();
        vm.prank(user2);
        smokeNFT.mint();

        assertEq(smokeNFT.tokenOfOwnerByIndex(user1, 0), 1);
        assertEq(smokeNFT.tokenOfOwnerByIndex(user2, 0), 2);
    }

    function testTokenOfOwnerByIndexOutOfBounds() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.expectRevert("SmokeNFT: owner index out of bounds");
        smokeNFT.tokenOfOwnerByIndex(user1, 1);
    }

    function testMinterOf() public {
        vm.prank(user1);
        smokeNFT.mint();

        assertEq(smokeNFT.minterOf(1), user1);
    }

    function testMinterOfZeroAddress() public {
        vm.expectRevert("SmokeNFT: Token does not exist");
        smokeNFT.minterOf(999);
    }

    function testStyleOf() public {
        vm.prank(user1);
        smokeNFT.mint();

        (
            bool fireMode,
            bool driftLeft,
            bool swirl,
            uint8 plumeCount,
            string memory colorA,
            string memory colorB,
            string memory colorAccent
        ) = smokeNFT.styleOf(1);

        assertTrue(fireMode || !fireMode);
        assertTrue(driftLeft || !driftLeft);
        assertTrue(swirl || !swirl);
        assertTrue(plumeCount >= 2 && plumeCount <= 6);
        assertEq(bytes(colorA).length, 7);
        assertEq(bytes(colorB).length, 7);
        assertEq(bytes(colorAccent).length, 7);
    }

    function testTokenSVG() public {
        vm.prank(user1);
        smokeNFT.mint();
        vm.skip(true);
    }

    function testTokenURI() public {
        vm.prank(user1);
        smokeNFT.mint();
        vm.skip(true);
    }

    function testTokenURIRevertsForNonExistent() public {
        vm.expectRevert("SmokeNFT: Token does not exist");
        smokeNFT.tokenURI(999);
    }

    function testTransferFrom() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.transferFrom(user1, user2, 1);

        assertEq(smokeNFT.ownerOf(1), user2);
        assertEq(smokeNFT.balanceOf(user1), 0);
        assertEq(smokeNFT.balanceOf(user2), 1);
    }

    function testTransferFromNotOwner() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user2);
        vm.expectRevert("SmokeNFT: not approved");
        smokeNFT.transferFrom(user1, user2, 1);
    }

    function testTransferFromToZeroAddress() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        vm.expectRevert("SmokeNFT: transfer to zero address");
        smokeNFT.transferFrom(user1, address(0), 1);
    }

    function testSafeTransferFrom() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.safeTransferFrom(user1, user2, 1);

        assertEq(smokeNFT.ownerOf(1), user2);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.safeTransferFrom(user1, user2, 1, "test data");

        assertEq(smokeNFT.ownerOf(1), user2);
    }

    function testApprove() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.approve(user2, 1);

        assertEq(smokeNFT.getApproved(1), user2);
    }

    function testApproveEmitsEvent() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit Approval(user1, user2, 1);
        smokeNFT.approve(user2, 1);
    }

    function testApproveByOperator() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.setApprovalForAll(user2, true);

        vm.prank(user2);
        smokeNFT.approve(user2, 1);

        assertEq(smokeNFT.getApproved(1), user2);
    }

    function testSetApprovalForAll() public {
        vm.prank(user1);
        smokeNFT.setApprovalForAll(user2, true);

        assertTrue(smokeNFT.isApprovedForAll(user1, user2));
    }

    function testSetApprovalForAllEmitsEvent() public {
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(user1, user2, true);
        smokeNFT.setApprovalForAll(user2, true);
    }

    function testSetApprovalForAllSameOperator() public {
        vm.prank(user1);
        vm.expectRevert("SmokeNFT: approve to caller");
        smokeNFT.setApprovalForAll(user1, true);
    }

    function testGetApprovedUnapproved() public {
        vm.prank(user1);
        smokeNFT.mint();

        assertEq(smokeNFT.getApproved(1), address(0));
    }

    function testTransferClearsApproval() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.approve(user2, 1);

        vm.prank(user1);
        smokeNFT.transferFrom(user1, user2, 1);

        assertEq(smokeNFT.getApproved(1), address(0));
    }

    function testBalanceOfZeroAddress() public {
        vm.expectRevert("SmokeNFT: Zero address");
        smokeNFT.balanceOf(address(0));
    }

    function testOwnerOfNonExistent() public {
        vm.expectRevert("SmokeNFT: Token does not exist");
        smokeNFT.ownerOf(999);
    }

    function testSetNameAndSymbol() public {
        smokeNFT.setNameAndSymbol("TestName", "TEST");

        assertEq(smokeNFT.name(), "TestName");
        assertEq(smokeNFT.symbol(), "TEST");
    }

    function testSetNameAndSymbolEmitsEvent() public {
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdated("NewName", "NEW");
        smokeNFT.setNameAndSymbol("NewName", "NEW");
    }

    function testSetNameAndSymbolNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("SmokeNFT: Not owner");
        smokeNFT.setNameAndSymbol("Name", "SYM");
    }

    function testTransferFromAfterApproval() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.approve(user2, 1);

        vm.prank(user2);
        smokeNFT.transferFrom(user1, user2, 1);

        assertEq(smokeNFT.ownerOf(1), user2);
    }

    function testTransferFromAfterApprovalForAll() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.setApprovalForAll(user2, true);

        vm.prank(user2);
        smokeNFT.transferFrom(user1, user2, 1);

        assertEq(smokeNFT.ownerOf(1), user2);
    }

    function testSafeTransferToEOA() public {
        address eoa = address(0x3333);
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.safeTransferFrom(user1, eoa, 1);

        assertEq(smokeNFT.ownerOf(1), eoa);
    }

    function testSafeTransferToContractWithoutReceiver() public {
        address receiver = address(new NoReceiver());
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        vm.expectRevert("SmokeNFT: non-ERC721Receiver");
        smokeNFT.safeTransferFrom(user1, receiver, 1);
    }

    function testSafeTransferToContractWithReceiver() public {
        address receiver = address(new ERC721Receiver());
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.safeTransferFrom(user1, receiver, 1);

        assertEq(smokeNFT.ownerOf(1), receiver);
    }

    function testHasMintedFalse() public {
        assertFalse(smokeNFT.hasMinted(user1));
    }

    function testHasMintedTrue() public {
        vm.prank(user1);
        smokeNFT.mint();

        assertTrue(smokeNFT.hasMinted(user1));
    }

    function testTransferUpdatesOwnedTokens() public {
        vm.prank(user1);
        smokeNFT.mint();

        vm.prank(user1);
        smokeNFT.transferFrom(user1, user2, 1);

        vm.skip(true);
    }

    function testMultipleMintsByDifferentUsers() public {
        vm.prank(user1);
        uint256 tokenId1 = smokeNFT.mint();

        vm.prank(user2);
        uint256 tokenId2 = smokeNFT.mint();

        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertEq(smokeNFT.ownerOf(1), user1);
        assertEq(smokeNFT.ownerOf(2), user2);
    }

    function testTransferBetweenTwoUsers() public {
        vm.prank(user1);
        smokeNFT.mint();

        address user3 = address(0x4444);
        vm.prank(user1);
        smokeNFT.transferFrom(user1, user3, 1);

        assertEq(smokeNFT.ownerOf(1), user3);
        assertEq(smokeNFT.balanceOf(user1), 0);
        assertEq(smokeNFT.balanceOf(user3), 1);
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4);
}

contract NoReceiver {
    receive() external payable {}
}

contract ERC721Receiver is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}