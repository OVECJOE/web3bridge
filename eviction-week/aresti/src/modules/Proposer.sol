// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IProposer} from "../interfaces/IProposer.sol";
import {IQueue} from "../interfaces/IQueue.sol";
import {IAuthorizer} from "../interfaces/IAuthorizer.sol";

contract Proposer is IProposer, Ownable {
    address public immutable i_queue;
    address public immutable i_authorizer;
    IVotes public immutable i_token;

    uint40 public constant VOTING_DELAY = 1 days;
    uint40 public constant VOTING_PERIOD = 3 days;
    uint256 public constant PROPOSAL_THRESHOLD = 100_000e18;

    bytes32 public constant PROPOSE_TYPEHASH =
        keccak256("Propose(uint256 proposalId,uint256 nonce)");

    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => bool) private _proposalExists;
    mapping(uint256 => bytes32) private _queueIds;

    uint256 private _proposalCount;

    constructor(
        address _proposer,
        address _queue,
        address _authorizer,
        address _token
    ) Ownable(_proposer) {
        i_queue = _queue;
        i_authorizer = _authorizer;
        i_token = IVotes(_token);
    }

    function propose(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external returns (uint256 proposalId) {
        proposalId = this.hashProposal(_targets, _values, _calldatas, _description);
        _propose(msg.sender, proposalId, _targets, _values, _calldatas, _description);
    }

    function proposeBySig(
        address signer,
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description,
        bytes calldata signature
    ) external returns (uint256 proposalId) {
        proposalId = this.hashProposal(_targets, _values, _calldatas, _description);
        
        uint256 nonce = IAuthorizer(i_authorizer).consumeNonce(signer);
        bytes32 structHash = keccak256(abi.encode(PROPOSE_TYPEHASH, proposalId, nonce));
        IAuthorizer(i_authorizer).verifyAuth(signer, structHash, signature);

        _propose(signer, proposalId, _targets, _values, _calldatas, _description);
    }

    function _propose(
        address proposer,
        uint256 proposalId,
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) internal {
        require(
            _targets.length == _values.length && _targets.length == _calldatas.length,
            InvalidProposalPayload()
        );
        require(!_proposalExists[proposalId], ProposalAlreadyExists());
        
        // Flash-loan and spam defense: Must have threshold tokens from previous block
        require(
            i_token.getPastVotes(proposer, block.timestamp - 1) >= PROPOSAL_THRESHOLD,
            "Below threshold"
        );

        uint40 startAt = uint40(block.timestamp + VOTING_DELAY);

        _proposals[proposalId] = Proposal({
            proposalHash: proposalId,
            status: ProposalStatus.Pending,
            description: _description,
            voteStartedAt: startAt,
            voteEndAt: startAt + VOTING_PERIOD,
            executedAt: 0,
            forVotes: 0,
            againstVotes: 0
        });

        _proposalExists[proposalId] = true;
        _proposalCount++;

        emit ProposalCreated(
            proposalId,
            proposer,
            _targets,
            _values,
            _calldatas,
            _description
        );
    }

    function cancel(uint256 _proposalId) external {
        require(_proposalExists[_proposalId], ProposalDoesNotExist());
        require(hasReachedThreshold(_proposalId), ProposalNotSucceeded());
        _proposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId, msg.sender);
    }

    function castVote(uint256 proposalId, uint8 support) external returns (uint256) {
        require(_proposalExists[proposalId], ProposalDoesNotExist());
        Proposal storage proposal = _proposals[proposalId];
        
        require(block.timestamp >= proposal.voteStartedAt, VotingNotActive());
        require(block.timestamp < proposal.voteEndAt, VotingNotActive());
        require(!hasVoted[proposalId][msg.sender], AlreadyVoted());

        // Snapshot voting power from exactly when the vote started
        uint256 weight = i_token.getPastVotes(msg.sender, proposal.voteStartedAt);
        require(weight > 0, "No voting power");

        if (support == 1) {
            proposal.forVotes += weight;
        } else if (support == 0) {
            proposal.againstVotes += weight;
        } else {
            revert("Invalid vote type");
        }

        hasVoted[proposalId][msg.sender] = true;

        if (proposal.status == ProposalStatus.Pending) {
            proposal.status = ProposalStatus.Active;
        }

        emit VoteCast(msg.sender, proposalId, support, weight);
        return weight;
    }

    function queue(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external returns (bytes32 queueId) {
        uint256 proposalId = _hashProposal(
            _targets,
            _values,
            _calldatas,
            _description
        );

        require(_proposalExists[proposalId], ProposalDoesNotExist());
        require(hasReachedThreshold(proposalId), ProposalNotSucceeded());

        _proposals[proposalId].status = ProposalStatus.Queued;

        queueId = IQueue(i_queue).queueProposal(
            _targets,
            _values,
            _calldatas,
            _description
        );

        _queueIds[proposalId] = queueId;

        emit ProposalQueued(proposalId, queueId, uint40(block.timestamp));
    }

    function execute(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external payable returns (uint256 proposalId) {
        proposalId = _hashProposal(_targets, _values, _calldatas, _description);

        require(_proposalExists[proposalId], ProposalDoesNotExist());
        require(
            _proposals[proposalId].status == ProposalStatus.Queued,
            ProposalNotSucceeded()
        );

        _proposals[proposalId].status = ProposalStatus.Executed;
        _proposals[proposalId].executedAt = uint40(block.timestamp);

        IQueue(i_queue).executeNext(
            _targets,
            _values,
            _calldatas,
            _description
        );

        emit ProposalExecuted(proposalId, msg.sender);
    }

    function hashProposal(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external pure returns (uint256) {
        return _hashProposal(_targets, _values, _calldatas, _description);
    }

    function hasReachedThreshold(
        uint256 _proposalId
    ) public view returns (bool) {
        require(_proposalExists[_proposalId], ProposalDoesNotExist());
        Proposal storage proposal = _proposals[_proposalId];
        
        if (block.timestamp <= proposal.voteEndAt) return false;
        
        uint256 quorum = 400_000e18; // 400k tokens
        if (proposal.forVotes < quorum) return false;
        return proposal.forVotes > proposal.againstVotes;
    }

    function getProposal(
        uint256 _proposalId
    ) external view returns (Proposal memory) {
        require(_proposalExists[_proposalId], ProposalDoesNotExist());
        return _proposals[_proposalId];
    }

    function _hashProposal(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(_targets, _values, _calldatas, _description)
                )
            );
    }
}
