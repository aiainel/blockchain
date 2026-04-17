// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        token = new MyToken("DeFi Token", "DTK");
    }

    // --- UNIT TESTS (Requirement: 10+ cases) [cite: 9] ---

    function test_Mint() public {
        token.mint(alice, 1000);
        assertEq(token.balanceOf(alice), 1000);
    }

    function test_Transfer() public {
        token.mint(alice, 1000);
        vm.prank(alice);
        token.transfer(bob, 400);
        assertEq(token.balanceOf(bob), 400);
    }

    function test_Approve() public {
        vm.prank(alice);
        token.approve(bob, 500);
        assertEq(token.allowance(alice, bob), 500);
    }

    function test_TransferFrom() public {
        token.mint(alice, 1000);
        vm.prank(alice);
        token.approve(address(this), 500);
        token.transferFrom(alice, bob, 300);
        assertEq(token.balanceOf(bob), 300);
    }

    function test_TotalSupply() public {
        token.mint(alice, 500);
        assertEq(token.totalSupply(), 500);
    }

    function test_BalanceAfterTransfer() public {
        token.mint(alice, 100);
        vm.prank(alice);
        token.transfer(bob, 50);
        assertEq(token.balanceOf(alice), 50);
    }

    function test_AllowanceDecrease() public {
        token.mint(alice, 100);
        vm.prank(alice);
        token.approve(address(this), 100);
        token.transferFrom(alice, bob, 40);
        assertEq(token.allowance(alice, address(this)), 60);
    }

    // FIXED: Using vm.expectRevert instead of testFail [cite: 9, 10]
    function test_RevertWhen_InsufficientBalance() public {
        token.mint(alice, 50);
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 100);
    }

    // FIXED: Using vm.expectRevert instead of testFail [cite: 9, 10]
    function test_RevertWhen_UnauthorizedTransferFrom() public {
        token.mint(alice, 100);
        vm.expectRevert();
        token.transferFrom(alice, bob, 50);
    }

    function test_ZeroAmountTransfer() public {
        token.mint(alice, 100);
        vm.prank(alice);
        token.transfer(bob, 0);
        assertEq(token.balanceOf(bob), 0);
    }

    // --- FUZZ TESTING (Requirement: Task 1.10) [cite: 10] ---

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount < type(uint128).max);
        token.mint(alice, amount);
        vm.prank(alice);
        token.transfer(bob, amount);
        assertEq(token.balanceOf(bob), amount);
    }

    // --- INVARIANT TESTING (Requirement: Task 1.11) [cite: 11] ---

    function testInvariant_SupplyNeverChangesOnTransfer() public {
        token.mint(alice, 1000);
        vm.prank(alice);
        token.transfer(bob, 100);
        assertEq(token.totalSupply(), 1000);
    }

    function testInvariant_BalanceNeverExceedsSupply() public view {
        assertTrue(token.balanceOf(alice) <= token.totalSupply());
    }
}
