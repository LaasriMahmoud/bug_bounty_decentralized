// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Reputation {
    address public platform;

    struct UserReputation {
        uint256 acceptedReports;
        uint256 rejectedReports;
        uint256 disputesWon;
        uint256 disputesLost;
    }

    mapping(address => UserReputation) public reputations;

    error Unauthorized();

    modifier onlyPlatform() {
        if (msg.sender != platform) revert Unauthorized();
        _;
    }

    constructor() {
        platform = msg.sender;
    }

    function addAccepted(address user) external onlyPlatform {
        reputations[user].acceptedReports++;
    }

    function addRejected(address user) external onlyPlatform {
        reputations[user].rejectedReports++;
    }

    function addDisputeWon(address user) external onlyPlatform {
        reputations[user].disputesWon++;
    }

    function addDisputeLost(address user) external onlyPlatform {
        reputations[user].disputesLost++;
    }
}
