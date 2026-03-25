// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BugBountyPlatform} from "../src/BugBountyPlatform.sol";
import {IBugBounty} from "../src/interfaces/IBugBounty.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract BugBountyPlatformTest is Test {
    BugBountyPlatform public platform;
    MockUSDC public usdc;

    address public treasury = address(0x10);
    address public owner = address(0x20);
    address public researcher = address(0x30);
    address[] public committee = [address(0x41), address(0x42), address(0x43)];

    function setUp() public {
        platform = new BugBountyPlatform(treasury);
        usdc = new MockUSDC(address(this));
        usdc.mint(owner, 10000 * 10**6);
        usdc.mint(researcher, 1000 * 10**6);
    }

    function test_CreateAndFundBounty() public {
        vm.startPrank(owner);
        uint256 bountyId = platform.createBounty(
            address(usdc),
            5000 * 10**6,
            50 * 10**6,
            uint64(block.timestamp + 30 days),
            committee,
            2
        );

        usdc.approve(address(platform), 5000 * 10**6);
        platform.fundBounty(bountyId, 5000 * 10**6);
        
        vm.stopPrank();

        // Check if escrow was funded
        (,,,,,,,, uint256 escrowBalance) = platform.bounties(bountyId);
        assertEq(escrowBalance, 5000 * 10**6);
    }

    function test_SubmitReportAndVote() public {
        vm.startPrank(owner);
        uint256 bountyId = platform.createBounty(
            address(usdc),
            5000 * 10**6,
            50 * 10**6,
            uint64(block.timestamp + 30 days),
            committee,
            2
        );
        usdc.approve(address(platform), 5000 * 10**6);
        platform.fundBounty(bountyId, 5000 * 10**6);
        vm.stopPrank();

        vm.startPrank(researcher);
        usdc.approve(address(platform), 50 * 10**6);
        uint256 reportId = platform.submitReport(
            bountyId, 
            bytes32("commitHash"), 
            bytes32("cidDigest"), 
            bytes32("hSteps"), 
            bytes32("hImpact"), 
            bytes32("hPoc")
        );
        vm.stopPrank();

        // Committee votes Accept
        vm.prank(committee[0]);
        platform.voteReport(bountyId, reportId, true);
        
        vm.prank(committee[1]);
        platform.voteReport(bountyId, reportId, true);

        // Finalize 
        platform.finalizeReport(bountyId, reportId);

        // Researcher should receive reward + stake back
        assertEq(usdc.balanceOf(researcher), (1000 * 10**6) + (5000 * 10**6));
    }
}
