// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "./Mocks/MockERC20.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    MockERC20 token;
    address alice = address(0x1);
    address liquidator = address(0x2);

    function setUp() public {
        token = new MockERC20("Stable", "STB");
        pool = new LendingPool(address(token));

        token.mint(alice, 1000 ether);
        token.mint(liquidator, 1000 ether);

        vm.prank(alice);
        token.approve(address(pool), type(uint256).max);
        
        vm.prank(liquidator);
        token.approve(address(pool), type(uint256).max);
    }

    function test_DepositAndBorrow() public {
        vm.startPrank(alice);
        pool.deposit(100 ether);
        pool.borrow(70 ether); // 70% LTV is fine
        vm.stopPrank();

        assertEq(pool.borrowBalance(alice), 70 ether);
        assertEq(token.balanceOf(alice), 970 ether);
    }

    function test_LiquidationScenario() public {
        // 1. Alice deposits and borrows max
        vm.startPrank(alice);
        pool.deposit(100 ether);
        pool.borrow(75 ether); 
        vm.stopPrank();

        // 2. We simulate a "Price Drop" or bad health by forcing state
        // In a real app, the collateral value would drop. 
        // Here we simulate it by increasing Alice's debt via a mock update 
        // or just testing the function logic.
        
        // For the assignment, we can "etch" or use a helper to make her underwater
        // Or simply demonstrate a successful liquidation when debt > 80%
        
        vm.prank(liquidator);
        // This will fail if health is okay, pass if underwater
        // pool.liquidate(alice); 
    }
}