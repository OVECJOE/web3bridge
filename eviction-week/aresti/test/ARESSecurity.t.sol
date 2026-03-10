// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {MockARESToken, MaliciousTarget} from "./Mocks.sol";
import {Authorizer} from "../src/modules/Authorizer.sol";
import {Distributor} from "../src/modules/Distributor.sol";
import {Proposer} from "../src/modules/Proposer.sol";
import {Queue} from "../src/modules/Queue.sol";
import {ARESTreasury} from "../src/core/ARESTreasury.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ARESSecurityTest is Test {
    MockARESToken public token;
    Authorizer public authorizer;
    Queue public queue;
    Proposer public proposer;
    Distributor public distributor;
    ARESTreasury public treasury;

    address public admin = address(1);
    uint256 public alicePk = 0x1234;
    address public alice = vm.addr(alicePk);
    uint256 public bobPk = 0x5678;
    address public bob = vm.addr(bobPk);

    bytes32 constant PROPOSE_TYPEHASH = keccak256("Propose(uint256 proposalId,uint256 nonce)");

    function setUp() public {
        vm.startPrank(admin);
        token = new MockARESToken();
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        queue = new Queue(2 days, executors, admin);
        authorizer = new Authorizer("ARES", "1", admin);
        proposer = new Proposer(admin, address(queue), address(authorizer), address(token));
        
        bytes32 PROPOSER_ROLE = queue.timelock().PROPOSER_ROLE();
        queue.timelock().grantRole(PROPOSER_ROLE, address(queue));
        queue.setProposer(address(proposer));

        treasury = new ARESTreasury(address(queue.timelock()));
        vm.deal(address(treasury), 1000 ether);

        distributor = new Distributor(address(token), address(queue.timelock()));
        authorizer.transferOwnership(address(proposer));

        token.mint(alice, 500_000 ether); // Meets threshold
        vm.stopPrank();

        vm.prank(alice);
        token.delegate(alice);
        
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
    }

    // 1. Reentrancy: Attempt to re-enter ARESTreasury during execution
    function test_RevertIf_Reentrancy() public {
        MaliciousTarget maliciousTarget = new MaliciousTarget(address(treasury));
        
        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("execute(address,uint256,bytes)", address(maliciousTarget), 1 ether, abi.encodeWithSignature("fallbackCall()"));
        string memory description = "Reentrancy Attack";

        vm.prank(alice);
        uint256 proposalId = proposer.propose(targets, values, calldatas, description);

        vm.warp(block.timestamp + proposer.VOTING_DELAY() + 1);
        vm.prank(alice);
        proposer.castVote(proposalId, 1);
        vm.warp(block.timestamp + proposer.VOTING_PERIOD() + 1);

        proposer.queue(targets, values, calldatas, description);
        vm.warp(block.timestamp + 2 days + 1);

        // This should fail because MaliciousTarget's receive() tries to call treasury.execute again
        vm.expectRevert();
        proposer.execute(targets, values, calldatas, description);
    }

    // 2. Signature Replay (same nonce twice)
    function test_RevertIf_SignatureReplay() public {
        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("execute(address,uint256,bytes)", bob, 10 ether, "");
        string memory desc1 = "Sig Replay 1";
        
        uint256 proposalId1 = proposer.hashProposal(targets, values, calldatas, desc1);
        uint256 nonce = authorizer.getNonce(alice);
        bytes32 structHash = keccak256(abi.encode(PROPOSE_TYPEHASH, proposalId1, nonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", authorizer.DOMAIN_SEPARATOR(), structHash));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // First proposal uses nonce 0 and succeeds
        proposer.proposeBySig(alice, targets, values, calldatas, desc1, sig);

        // Attacker observes signature and tries to use it for a different proposal hash? No, the hash enforces payload integrity.
        // What if attacker tries to replay the exact same signature and payload on a different chain? chainid protects it.
        // What if attacker tries to replay the exact same transaction? ProposalAlreadyExists will revert.
        // So let's test if we can propose the *same* payload again if we somehow bypassed ProposalAlreadyExists (by canceling it).
        // If we cancel the proposal, it ceases to exist? No, it's marked Cancelled.
        // Let's test that using the signature *again* for ANY reason fails because the nonce is consumed.
        
        // Let's craft a new proposal with the same nonce but different payload, signed by alice. Wait, if signed by alice, she has to actually sign it.
        // Malicious actor replays the EXACT SAME signature.
        // Even if the proposal was somehow deleted or we try to propose by sig again, the nonce is incremented.
        vm.expectRevert();
        proposer.proposeBySig(alice, targets, values, calldatas, desc1, sig); // Reverts in Authorizer InvalidSigner or ProposalAlreadyExists
    }

    // 3. Signature Malleability (invalid s value)
    function test_RevertIf_SignatureMalleability() public {
        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        
        bytes memory malleableSig;
        {
            uint256 proposalId = proposer.hashProposal(targets, values, calldatas, "Sig Mal");
            bytes32 structHash = keccak256(abi.encode(PROPOSE_TYPEHASH, proposalId, authorizer.getNonce(alice)));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", authorizer.DOMAIN_SEPARATOR(), structHash));
            
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
            
            uint256 GROUP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
            malleableSig = abi.encodePacked(r, bytes32(GROUP_ORDER - uint256(s)), v == 27 ? uint8(28) : uint8(27));
        }

        // Should revert with InvalidSignatureS
        vm.expectRevert();
        proposer.proposeBySig(alice, targets, values, calldatas, "Sig Mal", malleableSig);
    }

    // 4. Double Claim (Merkle)
    function test_RevertIf_DoubleClaim() public {
        bytes32 root = 0x242857e4e16d4128fbfd84f2c00af906b677051df31d56ceec554a9388dfba4c; // pre-calculated
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0x1234567812345678123456781234567812345678123456781234567812345678; // Dummy, won't matter if we just mock the tree
        // We need a real merkle tree to pass the first verification. Let's just mock verification or build a small rust-like tree in solidity?
        // Actually, we can just use the exact node as root, so proof is empty.
        bytes32 node = keccak256(abi.encodePacked(alice, uint256(100)));
        
        vm.prank(address(queue.timelock()));
        distributor.updateMerkleRoot(node);
        
        token.mint(address(distributor), 1000);

        bytes32[] memory emptyProof = new bytes32[](0);

        // First claim succeeds
        distributor.claim(alice, 100, emptyProof);

        // Second claim should revert
        vm.expectRevert();
        distributor.claim(alice, 100, emptyProof);
    }

    // 5. Premature Execution (Before ETA)
    function test_RevertIf_PrematureExecution() public {
        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        string memory description = "Premature";

        vm.prank(alice);
        uint256 proposalId = proposer.propose(targets, values, calldatas, description);

        vm.warp(block.timestamp + proposer.VOTING_DELAY() + 1);
        vm.prank(alice);
        proposer.castVote(proposalId, 1);
        vm.warp(block.timestamp + proposer.VOTING_PERIOD() + 1);

        proposer.queue(targets, values, calldatas, description);
        
        // Fast forward 1 day (min delay is 2 days)
        vm.warp(block.timestamp + 1 days);

        // This should fail because time hasn't passed
        vm.expectRevert();
        proposer.execute(targets, values, calldatas, description);
    }

    // 6. Unauthorized Execution (Bypassing Queue)
    function test_RevertIf_UnauthorizedExecution() public {
        // Alice tries to call ARESTreasury directly
        vm.prank(alice);
        vm.expectRevert();
        treasury.execute(alice, 100 ether, "");
    }

    // 7. Flash Loan Governance (Vote in same block as minting token)
    function test_RevertIf_FlashLoanGovernance() public {
        // Bob gets flash loan of 1,000,000 tokens
        token.mint(bob, 1_000_000 ether);
        vm.prank(bob);
        token.delegate(bob);

        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        string memory description = "Flash Loan Vote";

        // Alice proposes
        vm.prank(alice);
        uint256 proposalId = proposer.propose(targets, values, calldatas, description);

        // Bob tries to vote immediately (reverts because VotingNotActive)
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSignature("VotingNotActive()"));
        proposer.castVote(proposalId, 1);
        
        // Even if Bob waits for voting delay, his flash loan has to be returned in the SAME block.
        // If he keeps it until voting starts, it's not a flash loan.
        // Also if Bob tries to propose immediately upon receiving tokens, the snapshot was block.timestamp - 1, so he has 0 weight.
        vm.prank(bob);
        vm.expectRevert();
        proposer.propose(targets, values, calldatas, "Bob Propose"); // Reverts "Below threshold"
    }

    // 8. Large Treasury Drain (Rate limiting)
    function test_RevertIf_TreasuryDrain() public {
        // Propose to drain 100% of treasury (1000 ETH)
        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("execute(address,uint256,bytes)", bob, 1000 ether, "");
        string memory description = "Drain";

        vm.prank(alice);
        uint256 proposalId = proposer.propose(targets, values, calldatas, description);

        vm.warp(block.timestamp + proposer.VOTING_DELAY() + 1);
        vm.prank(alice);
        proposer.castVote(proposalId, 1);
        vm.warp(block.timestamp + proposer.VOTING_PERIOD() + 1);

        proposer.queue(targets, values, calldatas, description);
        vm.warp(block.timestamp + 2 days + 1);

        // Should revert because 1000 ETH is > max daily limit (50 ETH)
        vm.expectRevert();
        proposer.execute(targets, values, calldatas, description);
    }
}
