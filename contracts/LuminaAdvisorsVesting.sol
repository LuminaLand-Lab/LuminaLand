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

contract LuminaAdvisorsVesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable luminaToken;

    struct AdvisorVesting {
        address beneficiary;
        uint256 totalAllocation;
        uint256 released;
        uint256 startTime;
    }

    AdvisorVesting[] public advisorVestings;
    mapping(address => uint256) public advisorIndex;

    uint256 public constant CLIFF_DURATION = 180 days;     // 6 mois
    uint256 public constant VESTING_DURATION = 540 days;   // 18 mois

    uint256 public constant TOTAL_ADVISORS_ALLOCATION = 45_000_000 * 10**18;

    event TokensReleased(address indexed beneficiary, uint256 amount);
    event AdvisorAdded(address indexed beneficiary, uint256 allocation);

    constructor(address _luminaToken) Ownable(msg.sender) {
        require(_luminaToken != address(0), "Token address cannot be zero");
        luminaToken = IERC20(_luminaToken);
    }

    function addAdvisor(address _beneficiary, uint256 _allocation) external onlyOwner {
        require(_beneficiary != address(0), "Beneficiary cannot be zero");
        require(_allocation > 0, "Allocation must be > 0");

        uint256 index = advisorVestings.length;
        advisorVestings.push(AdvisorVesting({
            beneficiary: _beneficiary,
            totalAllocation: _allocation,
            released: 0,
            startTime: block.timestamp
        }));

        advisorIndex[_beneficiary] = index;
        emit AdvisorAdded(_beneficiary, _allocation);
    }

    function vestedAmount(address _beneficiary) public view returns (uint256) {
        uint256 index = advisorIndex[_beneficiary];
        require(index < advisorVestings.length, "Advisor not found");

        AdvisorVesting storage vesting = advisorVestings[index];

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
        return vestedAmount(_beneficiary) - advisorVestings[advisorIndex[_beneficiary]].released;
    }

    function release() external nonReentrant {
        uint256 index = advisorIndex[msg.sender];
        require(index < advisorVestings.length, "Not an advisor");

        uint256 amount = releasable(msg.sender);
        require(amount > 0, "Nothing to release");

        AdvisorVesting storage vesting = advisorVestings[index];
        vesting.released += amount;

        luminaToken.safeTransfer(vesting.beneficiary, amount);

        emit TokensReleased(vesting.beneficiary, amount);
    }

    function revoke(address _beneficiary) external onlyOwner {
        uint256 index = advisorIndex[_beneficiary];
        require(index < advisorVestings.length, "Advisor not found");

        AdvisorVesting storage vesting = advisorVestings[index];
        uint256 unreleased = vesting.totalAllocation - vesting.released;

        if (unreleased > 0) {
            vesting.released = vesting.totalAllocation;
            luminaToken.safeTransfer(owner(), unreleased);
        }
    }

    function getAllAdvisors() external view returns (AdvisorVesting[] memory) {
        return advisorVestings;
    }
}
