import { ethers } from 'ethers';

// ABI extracted from BugBountyPlatform.sol compilation (mocked here for the prototype)
export const BUG_BOUNTY_PLATFORM_ABI = [
    "function createBounty(address token, uint256 rewardAmount, uint256 stakeAmount, uint64 submissionDeadline, address[] calldata committee, uint8 thresholdK) external returns (uint256 bountyId)",
    "function fundBounty(uint256 bountyId, uint256 amount) external",
    "function submitReport(uint256 bountyId, bytes32 commitHash, bytes32 cidDigest, bytes32 hSteps, bytes32 hImpact, bytes32 hPoc) external returns (uint256 reportId)",
    "function voteReport(uint256 bountyId, uint256 reportId, bool accepted) external",
    "function raiseDispute(uint256 bountyId, uint256 reportId) external",
    "function commitVote(uint256 bountyId, uint256 reportId, bytes32 commitHash) external",
    "function revealVote(uint256 bountyId, uint256 reportId, bool vote, string calldata salt) external",
    "function resolveDispute(uint256 bountyId, uint256 reportId) external",
    "function finalizeReport(uint256 bountyId, uint256 reportId) external"
];

// Address of the deployed contract on Arbitrum Sepolia
export const CONTRACT_ADDRESS = "0xYourDeployedContractAddressHere";

/**
 * Helper to get a ready-to-use contract instance
 */
export async function getContract(signer: ethers.Signer) {
    return new ethers.Contract(CONTRACT_ADDRESS, BUG_BOUNTY_PLATFORM_ABI, signer);
}

/**
 * Create a new bug bounty program
 */
export async function createBounty(
    signer: ethers.Signer,
    token: string,
    rewardAmount: bigint,
    stakeAmount: bigint,
    deadline: number,
    committee: string[],
    threshold: number
) {
    const contract = await getContract(signer);
    const tx = await contract.createBounty(token, rewardAmount, stakeAmount, deadline, committee, threshold);
    return await tx.wait();
}

/**
 * Submit a report encrypted Hash details
 */
export async function submitReport(
    signer: ethers.Signer,
    bountyId: number,
    commitHash: string,
    cidDigest: string,
    hSteps: string,
    hImpact: string,
    hPoc: string
) {
    const contract = await getContract(signer);
    const tx = await contract.submitReport(bountyId, commitHash, cidDigest, hSteps, hImpact, hPoc);
    return await tx.wait();
}
