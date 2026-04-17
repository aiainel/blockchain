// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "./Mocks/MockERC20.sol";

contract AMMTest is Test {
    AMM public amm;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
        amm = new AMM(address(tokenA), address(tokenB));

        tokenA.mint(alice, 1000 ether);
        tokenB.mint(alice, 1000 ether);
        tokenA.mint(bob, 1000 ether);
        tokenB.mint(bob, 1000 ether);

        vm.startPrank(alice);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();
    }

    // --- LIQUIDITY TESTS ---
    function test_AddLiquidityFirst() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        assertEq(amm.reserveA(), 100 ether);
        assertEq(amm.reserveB(), 100 ether);
    }

    function test_AddLiquiditySubsequent() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        vm.prank(bob);
        amm.addLiquidity(50 ether, 50 ether);
        assertEq(amm.reserveA(), 150 ether);
    }

    // --- SWAP TESTS ---
    function test_SwapAforB() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        vm.prank(bob);
        uint256 out = amm.swap(address(tokenA), 10 ether, 0);
        assertTrue(out > 0);
    }

    function test_SwapBforA() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        vm.prank(bob);
        uint256 out = amm.swap(address(tokenB), 10 ether, 0);
        assertTrue(out > 0);
    }

    // --- PROTECTION & MATH TESTS ---
    function test_RevertWhen_SlippageTooHigh() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        vm.prank(bob);
        vm.expectRevert("Slippage: Output too low");
        amm.swap(address(tokenA), 10 ether, 100 ether);
    }

    function test_K_IncreasesAfterSwap() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        uint256 kBefore = amm.reserveA() * amm.reserveB();
        vm.prank(bob);
        amm.swap(address(tokenA), 10 ether, 0);
        uint256 kAfter = amm.reserveA() * amm.reserveB();
        assertTrue(kAfter > kBefore); // Due to 0.3% fee
    }

    // FIXED: Using vm.expectRevert instead of testFail
    function test_RevertWhen_SwapZeroAmount() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        vm.prank(bob);
        vm.expectRevert();
        amm.swap(address(tokenA), 0, 0);
    }

    function test_LargeSwapPriceImpact() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        vm.prank(bob);
        uint256 out = amm.swap(address(tokenA), 90 ether, 0);
        assertTrue(out < 50 ether);
    }

    // --- FUZZ TEST ---
    function testFuzz_Swap(uint256 amount) public {
        vm.assume(amount > 1000 && amount < 100 ether);
        vm.prank(alice);
        amm.addLiquidity(500 ether, 500 ether);
        vm.prank(bob);
        amm.swap(address(tokenA), amount, 0);
    }
}
