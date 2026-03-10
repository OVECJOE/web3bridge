// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IProposer {
    enum ProposalStatus {
        Pending,
        Queued,
        Active,
        Succeeded,
        Defeated,
        Executed,
        Cancelled
    }

    struct Proposal {
        uint256 proposalHash;
        ProposalStatus status;
        string description;
        uint40 voteStartedAt;
        uint40 voteEndAt;
        uint40 executedAt;
        uint256 forVotes;
        uint256 againstVotes;
    }

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string description
    );

    event ProposalCancelled(
        uint256 indexed proposalId,
        address indexed proposer
    );

    event ProposalQueued(
        uint256 indexed proposalId,
        bytes32 indexed queueId,
        uint40 eta
    );

    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed proposer
    );

    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint8 support,
        uint256 weight
    );

    error InvalidProposalPayload();
    error ProposalAlreadyExists();
    error ProposalDoesNotExist();
    error ProposalNotSucceeded();
    error VotingNotActive();
    error AlreadyVoted();

    function castVote(uint256 proposalId, uint8 support) external returns (uint256);

    function propose(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external returns (uint256);

    function proposeBySig(
        address signer,
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description,
        bytes calldata signature
    ) external returns (uint256);

    function cancel(uint256 _proposalId) external;

    function queue(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external returns (bytes32 queueId);

    function execute(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external payable returns (uint256);

    function hashProposal(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external view returns (uint256);

    function hasReachedThreshold(
        uint256 _proposalId
    ) external view returns (bool);
}
