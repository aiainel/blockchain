// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    IERC20 public immutable asset;

    mapping(address => uint256) public depositBalance;
    mapping(address => uint256) public borrowBalance;

    uint256 public constant LTV = 75; // 75% Loan-to-Value
    uint256 public constant LIQUIDATION_THRESHOLD = 80; // 80%

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    // User deposits collateral
    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        depositBalance[msg.sender] += amount;
    }

    // User borrows against collateral
    function borrow(uint256 amount) external {
        uint256 maxBorrow = (depositBalance[msg.sender] * LTV) / 100;
        require(borrowBalance[msg.sender] + amount <= maxBorrow, "Insufficient collateral");

        borrowBalance[msg.sender] += amount;
        asset.transfer(msg.sender, amount);
    }

    // Repay the loan
    function repay(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        borrowBalance[msg.sender] -= amount;
    }

    // Simple Liquidation: If debt > 80% of collateral, anyone can liquidate
    function liquidate(address user) external {
        uint256 collateralValue = depositBalance[user];
        uint256 debtValue = borrowBalance[user];

        // Check if underwater
        require(debtValue * 100 >= collateralValue * LIQUIDATION_THRESHOLD, "User is healthy");

        // Liquidator pays the debt
        asset.transferFrom(msg.sender, address(this), debtValue);

        // Liquidator gets the collateral (incentive)
        uint256 reward = depositBalance[user];
        depositBalance[user] = 0;
        borrowBalance[user] = 0;

        asset.transfer(msg.sender, reward);
    }
}
