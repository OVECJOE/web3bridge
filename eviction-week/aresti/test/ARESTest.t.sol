// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {MockARESToken, MaliciousTarget} from "./Mocks.sol";
import {Authorizer} from "../src/modules/Authorizer.sol";
import {Distributor} from "../src/modules/Distributor.sol";
import {Proposer} from "../src/modules/Proposer.sol";
import {Queue} from "../src/modules/Queue.sol";
import {ARESTreasury} from "../src/core/ARESTreasury.sol";

contract ARESTest is Test {
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

        // 1. Deploy Token
        token = new MockARESToken();

        // 2. Deploy Queue (Min delay: 2 days)
        address[] memory executors = new address[](1);
        executors[0] = address(0); // Anyone can execute queued payloads mapping to Timelock controller role setup
        queue = new Queue(2 days, executors, admin);

        // 3. Deploy Authorizer
        authorizer = new Authorizer("ARES", "1", admin);

        // 4. Deploy Proposer
        proposer = new Proposer(admin, address(queue), address(authorizer), address(token));
        
        // 5. Setup Timelock roles for Queue
        // timelock setup is internal to Queue, we need Proposer to be the only Proposer role
        bytes32 PROPOSER_ROLE = queue.timelock().PROPOSER_ROLE();
        queue.timelock().grantRole(PROPOSER_ROLE, address(queue)); // Queue schedules in its own Timelock wrapper

        queue.setProposer(address(proposer));

        // 6. Deploy Treasury
        treasury = new ARESTreasury(address(queue.timelock()));
        vm.deal(address(treasury), 1000 ether);

        // 7. Deploy Distributor
        distributor = new Distributor(address(token), address(queue.timelock()));

        // Give admin the power to consume nonces for tests easily? No, Authorizer is only callable by its owner (admin) but Proposer needs to call it!
        authorizer.transferOwnership(address(proposer));

        // Give Alice enough tokens to propose
        token.mint(alice, 500_000 ether);
        vm.stopPrank();

        vm.prank(alice);
        token.delegate(alice);
        
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
    }

    function test_ProposalLifecycle() public {
        // Setup payload
        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        // Execute a transfer from treasury to Bob
        calldatas[0] = abi.encodeWithSignature("execute(address,uint256,bytes)", bob, 10 ether, "");

        string memory description = "Send Bob 10 ETH";

        // Propose
        vm.prank(alice);
        uint256 proposalId = proposer.propose(targets, values, calldatas, description);

        // Fast forward past Voting Delay
        vm.warp(block.timestamp + proposer.VOTING_DELAY() + 1);

        // Vote
        vm.prank(alice);
        proposer.castVote(proposalId, 1); // For

        // Fast forward past Voting Period
        vm.warp(block.timestamp + proposer.VOTING_PERIOD() + 1);

        // Queue
        bytes32 queueId = proposer.queue(targets, values, calldatas, description);

        // Fast forward past Timelock Min Delay
        vm.warp(block.timestamp + 2 days + 1);

        uint256 bobBalBefore = bob.balance;

        // Execute
        proposer.execute(targets, values, calldatas, description);

        assertEq(bob.balance, bobBalBefore + 10 ether, "Bob did not receive funds");
    }
}
