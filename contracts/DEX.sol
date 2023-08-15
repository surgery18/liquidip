// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LiquidityPool.sol";
import "./LiquidityPoolFactory.sol";
import "./IERC20.sol";

contract DEX {
    LiquidityPoolFactory public factory;

    constructor(address _factory) {
        factory = LiquidityPoolFactory(_factory);
    }

    function swapByRoute(
        address[] memory route,
        uint amountIn,
        uint minAmountOut
    ) external {
        require(route.length >= 2, "Invalid route");
        require(amountIn > 0, "Amount must be greater than 0");

        uint amountOut;
        uint amountInNext = amountIn;

        for (uint i = 0; i < route.length - 1; i++) {
            address tokenIn = route[i];
            address tokenOut = route[i + 1];

            LiquidityPool pool = LiquidityPool(
                factory.getLiquidityPool(tokenIn, tokenOut)
            );
            amountOut = pool.swapTokens(tokenIn, tokenOut, amountInNext);

            amountInNext = amountOut;
        }

        require(
            amountOut >= minAmountOut,
            "Output amount is below specified minimum"
        );

        LiquidityPool pool = LiquidityPool(route[route.length - 1]);
        IERC20 outputToken = IERC20(pool.token1());
        require(
            outputToken.transferFrom(address(pool), msg.sender, amountOut),
            "Failed to transfer output tokens"
        );
    }

    function getRoute(
        address tokenA,
        address tokenB
    ) external view returns (address[] memory) {
        if (factory.hasPool(tokenA, tokenB)) {
            address[] memory route = new address[](2);
            route[0] = tokenA;
            route[1] = tokenB;
            return route;
        }

        uint256 tokenCount = factory.getTokensCount();
        address[] memory tokens = new address[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = factory.tokens(i);
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            if (
                factory.hasPool(tokenA, tokens[i]) &&
                factory.hasPool(tokens[i], tokenB)
            ) {
                address[] memory oneHopRoute = new address[](3);
                oneHopRoute[0] = tokenA;
                oneHopRoute[1] = tokens[i];
                oneHopRoute[2] = tokenB;
                return oneHopRoute;
            }
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                if (
                    factory.hasPool(tokenA, tokens[i]) &&
                    factory.hasPool(tokens[i], tokens[j]) &&
                    factory.hasPool(tokens[j], tokenB)
                ) {
                    address[] memory twoHopRoute = new address[](4);
                    twoHopRoute[0] = tokenA;
                    twoHopRoute[1] = tokens[i];
                    twoHopRoute[2] = tokens[j];
                    twoHopRoute[3] = tokenB;
                    return twoHopRoute;
                }
            }
        }

        revert("No route found");
    }

    function estimateOutput(
        address[] memory route,
        uint amountIn
    ) external view returns (uint) {
        require(route.length >= 2, "Invalid route");
        require(amountIn > 0, "Amount must be greater than 0");

        uint amountOut;

        for (uint i = 0; i < route.length - 1; i++) {
            LiquidityPool pool = LiquidityPool(
                factory.getLiquidityPool(route[i], route[i + 1])
            );
            require(
                address(pool) != address(0),
                "Liquidity pool does not exist for the given token pair"
            );

            amountOut = pool.getAmountOut(route[i], route[i + 1], amountIn);
            amountIn = amountOut;
        }

        return amountOut;
    }
}
