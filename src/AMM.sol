// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";

contract AMM {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    LPToken public immutable lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpAmount);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpAmount);
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new LPToken();
    }

    // Task Requirement: Implement getAmountOut using x * y = k 
    // Includes 0.3% fee 
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee deducted
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }

    // Task Requirement: addLiquidity() 
    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 shares) {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        // Simple LP share calculation (simplification for the assignment)
        if (lpToken.totalSupply() == 0) {
            shares = _sqrt(amountA * amountB);
        } else {
            shares = _min((amountA * lpToken.totalSupply()) / reserveA, (amountB * lpToken.totalSupply()) / reserveB);
        }

        require(shares > 0, "Insufficient liquidity minted");
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));

        lpToken.mint(msg.sender, shares);
        emit LiquidityAdded(msg.sender, amountA, amountB, shares);
    }

    // Task Requirement: swap() with slippage protection [cite: 36, 39]
    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        bool isTokenA = tokenIn == address(tokenA);
        (IERC20 tIn, IERC20 tOut, uint256 rIn, uint256 rOut) = isTokenA 
            ? (tokenA, tokenB, reserveA, reserveB) 
            : (tokenB, tokenA, reserveB, reserveA);

        tIn.transferFrom(msg.sender, address(this), amountIn);
        amountOut = getAmountOut(amountIn, rIn, rOut);
        
        // Slippage check 
        require(amountOut >= minAmountOut, "Slippage: Output too low");

        tOut.transfer(msg.sender, amountOut);
        
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
        
        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    // Helper functions
    function _sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint x, uint y) internal pure returns (uint) {
        return x <= y ? x : y;
    }
}