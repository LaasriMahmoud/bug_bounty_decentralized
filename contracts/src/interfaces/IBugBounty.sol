// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBugBounty {
    enum ReportStatus {
        Submitted,
        Accepted,
        Rejected,
        Disputed,
        Finalized
    }

    struct Bounty {
        address owner;
        IERC20 token;
        uint256 rewardAmount;
        uint256 stakeAmount;
        uint64 submissionDeadline;
        bool active;
        uint8 committeeSize;
        uint8 thresholdK;
        uint256 escrowBalance;
    }

    struct Report {
        address researcher;
        bytes32 commitHash;
        bytes32 cidDigest;
        bytes32 hSteps;
        bytes32 hImpact;
        bytes32 hPoc;
        uint256 stakeAmount;
        uint64 submittedAt;
        uint8 acceptVotes;
        uint8 rejectVotes;
        ReportStatus status;
        bool paid;
    }

    event BountyCreated(
        uint256 indexed bountyId,
        address indexed owner,
        address indexed token,
        uint256 rewardAmount,
        uint256 stakeAmount,
        uint64 submissionDeadline,
        uint8 committeeSize,
        uint8 thresholdK
    );

    event BountyFunded(uint256 indexed bountyId, uint256 amount);
    event ReportSubmitted(uint256 indexed bountyId, uint256 indexed reportId, address indexed researcher);
    event ReportVoted(uint256 indexed bountyId, uint256 indexed reportId, address indexed reviewer, bool accepted);
    event ReportFinalized(uint256 indexed bountyId, uint256 indexed reportId, ReportStatus result);
    event ReportDisputed(uint256 indexed bountyId, uint256 indexed reportId);

    error InvalidCommittee();
    error InvalidThreshold();
    error NotBountyOwner();
    error BountyInactive();
    error SubmissionClosed();
    error InsufficientEscrow();
    error NotCommitteeMember();
    error AlreadyVoted();
    error InvalidReport();
    error ReportNotSubmittable();
    error ReportNotFinalizable();
    error AlreadyPaid();
    error ReportNotDisputable();
    error NotAuthorized();
}
