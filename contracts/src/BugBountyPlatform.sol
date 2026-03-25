// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IBugBounty.sol";
import "./modules/Escrow.sol";
import "./modules/StakeManager.sol";
import "./modules/Reputation.sol";
import "./modules/DisputeModule.sol";

contract BugBountyPlatform is IBugBounty, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public bountyCount;
    address public treasury;

    Escrow public escrow;
    StakeManager public stakeManager;
    Reputation public reputation;
    DisputeModule public disputeModule;

    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => mapping(address => bool)) public isCommitteeMember;
    mapping(uint256 => uint256) public reportCount;
    mapping(uint256 => mapping(uint256 => Report)) public reports;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasVoted;

    modifier onlyBountyOwner(uint256 bountyId) {
        if (msg.sender != bounties[bountyId].owner) revert NotBountyOwner();
        _;
    }

    modifier onlyCommittee(uint256 bountyId) {
        if (!isCommitteeMember[bountyId][msg.sender]) revert NotCommitteeMember();
        _;
    }

    constructor(address _treasury) {
        treasury = _treasury;
        escrow = new Escrow();
        stakeManager = new StakeManager(_treasury);
        reputation = new Reputation();
        disputeModule = new DisputeModule();
    }

    function createBounty(
        address token,
        uint256 rewardAmount,
        uint256 stakeAmount,
        uint64 submissionDeadline,
        address[] calldata committee,
        uint8 thresholdK
    ) external returns (uint256 bountyId) {
        if (committee.length == 0) revert InvalidCommittee();
        if (thresholdK == 0 || thresholdK > committee.length) revert InvalidThreshold();
        if (submissionDeadline <= block.timestamp) revert SubmissionClosed();

        bountyId = bountyCount++;

        Bounty storage b = bounties[bountyId];
        b.owner = msg.sender;
        b.token = IERC20(token);
        b.rewardAmount = rewardAmount;
        b.stakeAmount = stakeAmount;
        b.submissionDeadline = submissionDeadline;
        b.active = true;
        b.committeeSize = uint8(committee.length);
        b.thresholdK = thresholdK;

        for (uint256 i = 0; i < committee.length; i++) {
            address member = committee[i];
            if (member == address(0) || isCommitteeMember[bountyId][member]) revert InvalidCommittee();
            isCommitteeMember[bountyId][member] = true;
        }

        emit BountyCreated(
            bountyId,
            msg.sender,
            token,
            rewardAmount,
            stakeAmount,
            submissionDeadline,
            uint8(committee.length),
            thresholdK
        );
    }

    function fundBounty(uint256 bountyId, uint256 amount) external onlyBountyOwner(bountyId) {
        Bounty storage b = bounties[bountyId];
        b.token.safeTransferFrom(msg.sender, address(this), amount);
        b.token.safeIncreaseAllowance(address(escrow), amount);
        escrow.deposit(bountyId, b.token, amount, address(this));
        
        b.escrowBalance += amount;

        emit BountyFunded(bountyId, amount);
    }

    function submitReport(
        uint256 bountyId,
        bytes32 commitHash,
        bytes32 cidDigest,
        bytes32 hSteps,
        bytes32 hImpact,
        bytes32 hPoc
    ) external nonReentrant returns (uint256 reportId) {
        Bounty storage b = bounties[bountyId];

        if (!b.active) revert BountyInactive();
        if (block.timestamp > b.submissionDeadline) revert SubmissionClosed();

        reportId = reportCount[bountyId]++;

        reports[bountyId][reportId] = Report({
            researcher: msg.sender,
            commitHash: commitHash,
            cidDigest: cidDigest,
            hSteps: hSteps,
            hImpact: hImpact,
            hPoc: hPoc,
            stakeAmount: b.stakeAmount,
            submittedAt: uint64(block.timestamp),
            acceptVotes: 0,
            rejectVotes: 0,
            status: ReportStatus.Submitted,
            paid: false
        });

        if (b.stakeAmount > 0) {
            b.token.safeTransferFrom(msg.sender, address(this), b.stakeAmount);
            b.token.safeIncreaseAllowance(address(stakeManager), b.stakeAmount);
            stakeManager.lockStake(reportId, b.token, b.stakeAmount, address(this));
        }

        emit ReportSubmitted(bountyId, reportId, msg.sender);
    }

    function voteReport(uint256 bountyId, uint256 reportId, bool accepted) external onlyCommittee(bountyId) {
        Report storage r = reports[bountyId][reportId];
        Bounty storage b = bounties[bountyId];

        if (r.researcher == address(0)) revert InvalidReport();
        if (r.status != ReportStatus.Submitted) revert ReportNotSubmittable();
        if (hasVoted[bountyId][reportId][msg.sender]) revert AlreadyVoted();

        hasVoted[bountyId][reportId][msg.sender] = true;

        if (accepted) {
            r.acceptVotes += 1;
            if (r.acceptVotes >= b.thresholdK) {
                r.status = ReportStatus.Accepted;
            }
        } else {
            r.rejectVotes += 1;
            if (r.rejectVotes >= b.thresholdK) {
                r.status = ReportStatus.Rejected;
            }
        }

        emit ReportVoted(bountyId, reportId, msg.sender, accepted);
    }
    
    function raiseDispute(uint256 bountyId, uint256 reportId) external nonReentrant {
        Report storage r = reports[bountyId][reportId];
        Bounty storage b = bounties[bountyId];
        if (msg.sender != r.researcher && msg.sender != b.owner) revert NotAuthorized();
        if (r.status != ReportStatus.Submitted && r.status != ReportStatus.Rejected) revert ReportNotDisputable();
        
        r.status = ReportStatus.Disputed;
        disputeModule.raiseDispute(reportId);
        emit ReportDisputed(bountyId, reportId);
    }

    function commitVote(uint256 bountyId, uint256 reportId, bytes32 commitHash) external onlyCommittee(bountyId) {
        Report storage r = reports[bountyId][reportId];
        if (r.status != ReportStatus.Disputed) revert ReportNotDisputable();
        disputeModule.commitVote(reportId, msg.sender, commitHash);
    }

    function revealVote(uint256 bountyId, uint256 reportId, bool vote, string calldata salt) external onlyCommittee(bountyId) {
        Report storage r = reports[bountyId][reportId];
        if (r.status != ReportStatus.Disputed) revert ReportNotDisputable();
        disputeModule.revealVote(reportId, msg.sender, vote, salt);
    }

    function resolveDispute(uint256 bountyId, uint256 reportId) external nonReentrant {
        Report storage r = reports[bountyId][reportId];
        Bounty storage b = bounties[bountyId];
        if (r.status != ReportStatus.Disputed) revert ReportNotDisputable();

        ReportStatus resolvedStatus = disputeModule.resolveDispute(reportId, b.thresholdK);
        r.status = resolvedStatus;

        if (resolvedStatus == ReportStatus.Accepted) {
            reputation.addDisputeWon(r.researcher);
            reputation.addDisputeLost(b.owner);
        } else {
            reputation.addDisputeLost(r.researcher);
            reputation.addDisputeWon(b.owner);
        }

        _finalize(bountyId, reportId, resolvedStatus);
    }

    function finalizeReport(uint256 bountyId, uint256 reportId) external nonReentrant {
        Report storage r = reports[bountyId][reportId];
        if (r.status != ReportStatus.Accepted && r.status != ReportStatus.Rejected) {
            revert ReportNotFinalizable();
        }
        _finalize(bountyId, reportId, r.status);
    }

    function _finalize(uint256 bountyId, uint256 reportId, ReportStatus finalStatus) internal {
        Report storage r = reports[bountyId][reportId];
        Bounty storage b = bounties[bountyId];

        if (r.paid) revert AlreadyPaid();

        r.paid = true;
        r.status = ReportStatus.Finalized;

        if (finalStatus == ReportStatus.Accepted) {
            if (b.escrowBalance < b.rewardAmount) revert InsufficientEscrow();
            b.escrowBalance -= b.rewardAmount;
            
            reputation.addAccepted(r.researcher);

            if (b.rewardAmount > 0) {
                escrow.release(bountyId, b.token, r.researcher, b.rewardAmount);
            }
            if (r.stakeAmount > 0) {
                stakeManager.refundStake(reportId, b.token, r.researcher);
            }

            emit ReportFinalized(bountyId, reportId, ReportStatus.Accepted);
        } else {
            reputation.addRejected(r.researcher);

            if (r.stakeAmount > 0) {
                stakeManager.slashStake(reportId, b.token);
            }

            emit ReportFinalized(bountyId, reportId, ReportStatus.Rejected);
        }
    }
}
