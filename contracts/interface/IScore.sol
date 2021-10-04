// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IScore {
    function updateScore(address user, uint256 changeBy) external;
}
