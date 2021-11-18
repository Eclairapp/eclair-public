// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

contract Score {
    using Counters for Counters.Counter;

    /** STRUCTS */
    struct ScoreDetails {
        uint256 score;
        uint256 pendingReward;
    }

    /** STATE VARIABLES */
    // address of  the marketplace. This is the only address that can mutate the user's score.
    address public market;

    mapping(address => ScoreDetails) public scores;

    uint256 public lastUpdated = 0;
    uint256 public unitsCounted = 0 ether;
    uint256 public totalScore = 0;
    Counters.Counter private totalUsers;
    address[] private allUsers;

    event RewardsUpdated(uint256 updatedAt, uint256 balance);
    event RewardClaimed(address indexed user, uint256 amount);
    event ScoreUpdated(address indexed user, uint256 current);

    constructor(address marketAddress) {
        market = marketAddress;
        lastUpdated = block.timestamp;
    }

    receive() external payable {}

    /** FUNCTIONS */

    // Increment the user's score by a specified amount. Can only be called by the marketplace.
    function updateScore(address user, uint256 changeBy) external onlyMarket {
        // Check if user is already present.
        // console.log("Current Score Balance: %s", address(this).balance);
        bool isUserPresent = false;
        uint256 total = totalUsers.current();
        for (uint256 i = 0; i < total; i++) {
            if (allUsers[i] == user) {
                isUserPresent = true;
                break;
            }
        }

        // If the user is not present, add the user and increment the counter.
        if (!isUserPresent) {
            allUsers.push(user);
            totalUsers.increment();
        }

        // Update the user's score.
        scores[user].score = scores[user].score + changeBy;
        totalScore += changeBy;
        emit ScoreUpdated(user, scores[user].score);
    }

    function updateRewards() public {
        uint256 toReward = (address(this).balance - unitsCounted);

        require(toReward > 0, "Rewards to distribute is 0");
        // console.log("Updating reward");
        // console.log("To reward", toReward);
        // console.log("Total score", totalScore);

        for (uint256 i = 0; i < totalUsers.current(); i++) {
            ScoreDetails storage current = scores[allUsers[i]];
            if (current.score > 0) {
                current.pendingReward += ((toReward * current.score) /
                    totalScore);
                current.score = 0;
            }
        }

        unitsCounted += toReward;
        lastUpdated = block.timestamp;

        emit RewardsUpdated(lastUpdated, unitsCounted);
    }

    function claim() public {
        ScoreDetails storage details = scores[msg.sender];
        require(details.pendingReward > 0);
        payable(msg.sender).transfer(details.pendingReward);
        details.pendingReward = 0;

        emit RewardClaimed(msg.sender, details.pendingReward);
    }

    function getScoreByAddress(address user) public view returns (uint256) {
        return scores[user].score;
    }

    function getPendingRewardByAddress(address user)
        public
        view
        returns (uint256)
    {
        return scores[user].pendingReward;
    }

    /** MODIFIERS */

    // Modifier to only let the marketplace call the function.
    modifier onlyMarket() {
        require(msg.sender == market);
        _;
    }

    modifier atleastOneDay() {
        require((block.timestamp - lastUpdated) > 1 days);
        _;
    }
}
