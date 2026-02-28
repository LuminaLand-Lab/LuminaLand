// SPDX-License-Identifier: BSL-1.1
// Copyright © 2026 LuminaLand-Lab. All Rights Reserved.
// Licensed under Business Source License 1.1
// Commercial use prohibited until February 28, 2030
// Contact for early commercial license or acquisition: contact@luminaland.org

pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract LuminaCoreTeamVesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable luminaToken;

    struct TeamMemberVesting {
        address beneficiary;
        uint256 totalAllocation;
        uint256 released;
        uint256 startTime;
    }

    TeamMemberVesting[] public teamVestings;
    mapping(address => uint256) public teamIndex;

    uint256 public constant CLIFF_DURATION = 180 days;     // 6 mois
    uint256 public constant VESTING_DURATION = 540 days;   // 18 mois

    uint256 public constant TOTAL_CORE_TEAM_ALLOCATION = 105_000_000 * 10**18; // 105 M LUMI

    event TokensReleased(address indexed beneficiary, uint256 amount);
    event TeamMemberAdded(address indexed beneficiary, uint256 allocation);

    constructor(address _luminaToken) Ownable(msg.sender) {
        require(_luminaToken != address(0), "Token address cannot be zero");
        luminaToken = IERC20(_luminaToken);
    }

    function addTeamMember(address _beneficiary, uint256 _allocation) external onlyOwner {
        require(_beneficiary != address(0), "Beneficiary cannot be zero");
        require(_allocation > 0, "Allocation must be > 0");

        uint256 index = teamVestings.length;
        teamVestings.push(TeamMemberVesting({
            beneficiary: _beneficiary,
            totalAllocation: _allocation,
            released: 0,
            startTime: block.timestamp
        }));

        teamIndex[_beneficiary] = index;
        emit TeamMemberAdded(_beneficiary, _allocation);
    }

    function vestedAmount(address _beneficiary) public view returns (uint256) {
        uint256 index = teamIndex[_beneficiary];
        require(index < teamVestings.length, "Team member not found");

        TeamMemberVesting storage vesting = teamVestings[index];

        if (block.timestamp < vesting.startTime + CLIFF_DURATION) {
            return 0;
        }

        if (block.timestamp >= vesting.startTime + CLIFF_DURATION + VESTING_DURATION) {
            return vesting.totalAllocation;
        }

        uint256 timeElapsedAfterCliff = block.timestamp - (vesting.startTime + CLIFF_DURATION);
        uint256 vested = Math.mulDiv(vesting.totalAllocation, timeElapsedAfterCliff, VESTING_DURATION);
        return vested;
    }

    function releasable(address _beneficiary) public view returns (uint256) {
        return vestedAmount(_beneficiary) - teamVestings[teamIndex[_beneficiary]].released;
    }

    function release() external nonReentrant {
        uint256 index = teamIndex[msg.sender];
        require(index < teamVestings.length, "Not a team member");

        uint256 amount = releasable(msg.sender);
        require(amount > 0, "Nothing to release");

        TeamMemberVesting storage vesting = teamVestings[index];
        vesting.released += amount;

        luminaToken.safeTransfer(vesting.beneficiary, amount);

        emit TokensReleased(vesting.beneficiary, amount);
    }

    function revoke(address _beneficiary) external onlyOwner {
        uint256 index = teamIndex[_beneficiary];
        require(index < teamVestings.length, "Team member not found");

        TeamMemberVesting storage vesting = teamVestings[index];
        uint256 unreleased = vesting.totalAllocation - vesting.released;

        if (unreleased > 0) {
            vesting.released = vesting.totalAllocation;
            luminaToken.safeTransfer(owner(), unreleased);
        }
    }

    function getAllTeamMembers() external view returns (TeamMemberVesting[] memory) {
        return teamVestings;
    }
}
