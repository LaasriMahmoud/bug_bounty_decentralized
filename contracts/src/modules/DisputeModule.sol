// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../interfaces/IBugBounty.sol";

contract DisputeModule {
    address public platform;

    enum Phase {
        None,
        Commit,
        Reveal,
        Resolved
    }

    struct Dispute {
        Phase phase;
        uint64 commitDeadline;
        uint64 revealDeadline;
        uint8 acceptVotes;
        uint8 rejectVotes;
    }

    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bytes32)) public commitments;
    mapping(uint256 => mapping(address => bool)) public hasRevealed;

    error Unauthorized();
    error InvalidPhase();
    error DeadlinePassed();
    error CommitNotMatching();
    error AlreadyCommitted();
    error AlreadyRevealed();

    modifier onlyPlatform() {
        if (msg.sender != platform) revert Unauthorized();
        _;
    }

    constructor() {
        platform = msg.sender;
    }

    function raiseDispute(uint256 reportId) external onlyPlatform {
        disputes[reportId] = Dispute({
            phase: Phase.Commit,
            commitDeadline: uint64(block.timestamp + 3 days),
            revealDeadline: uint64(block.timestamp + 6 days),
            acceptVotes: 0,
            rejectVotes: 0
        });
    }

    function commitVote(uint256 reportId, address committeeMember, bytes32 commitHash) external onlyPlatform {
        Dispute storage d = disputes[reportId];
        if (d.phase != Phase.Commit) revert InvalidPhase();
        if (block.timestamp > d.commitDeadline) revert DeadlinePassed();
        if (commitments[reportId][committeeMember] != bytes32(0)) revert AlreadyCommitted();

        commitments[reportId][committeeMember] = commitHash;
    }

    function revealVote(uint256 reportId, address committeeMember, bool vote, string calldata salt) external onlyPlatform {
        Dispute storage d = disputes[reportId];
        // Transition to reveal phase if deadline passed
        if (d.phase == Phase.Commit && block.timestamp > d.commitDeadline) {
            d.phase = Phase.Reveal;
        }
        if (d.phase != Phase.Reveal) revert InvalidPhase();
        if (block.timestamp > d.revealDeadline) revert DeadlinePassed();
        if (hasRevealed[reportId][committeeMember]) revert AlreadyRevealed();

        bytes32 expectedCommit = keccak256(abi.encodePacked(vote, salt));
        if (expectedCommit != commitments[reportId][committeeMember]) revert CommitNotMatching();

        hasRevealed[reportId][committeeMember] = true;
        if (vote) {
            d.acceptVotes++;
        } else {
            d.rejectVotes++;
        }
    }

    function resolveDispute(uint256 reportId, uint8 thresholdK) external onlyPlatform returns (IBugBounty.ReportStatus) {
        Dispute storage d = disputes[reportId];
        
        if (d.phase == Phase.Commit && block.timestamp > d.commitDeadline) {
            d.phase = Phase.Reveal;
        }
        
        bool thresholdReached = (d.acceptVotes >= thresholdK || d.rejectVotes >= thresholdK);
        bool revealPassed = (block.timestamp > d.revealDeadline);
        
        if (!thresholdReached && !revealPassed) revert InvalidPhase();
        
        d.phase = Phase.Resolved;

        if (d.acceptVotes >= thresholdK) {
            return IBugBounty.ReportStatus.Accepted;
        } else if (d.rejectVotes >= thresholdK) {
            return IBugBounty.ReportStatus.Rejected;
        } else {
            // Tie or not enough votes. Default to Rejected for anti-spam.
            return IBugBounty.ReportStatus.Rejected;
        }
    }
}
