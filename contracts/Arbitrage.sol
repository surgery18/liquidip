// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DEX.sol";
import "./FlashLoanProvider.sol";

contract Arbitrage {
    address public owner;
    DEX public dexA;
    DEX public dexB;
    FlashLoanProvider public flashLoanProvider;
    address public token0;
    address public token1;

    constructor(
        address _dexA,
        address _dexB,
        address _flashLoanProvider,
        address _token0,
        address _token1
    ) {
        owner = msg.sender;
        dexA = DEX(_dexA);
        dexB = DEX(_dexB);
        flashLoanProvider = FlashLoanProvider(_flashLoanProvider);
        token0 = _token0;
        token1 = _token1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Start the arbitrage by requesting a flash loan
    function startArbitrage(uint256 amount) external onlyOwner {
        flashLoanProvider.requestFlashLoan(token0, amount);
    }

    // This function is called by the Flash Loan provider once the loaned amount is received
    function executeFlashloan(
        uint256 amount,
        uint256 fee,
        address pool
    ) external {
        // First, we'll swap the borrowed amount on dexA for token1
        address[] memory routeA = new address[](2);
        routeA[0] = token0;
        routeA[1] = token1;

        IERC20(token0).approve(address(dexA), amount);

        // Here, we're assuming `swapByRoute` is a function in the DEX contract that handles the swap.
        // If not, you'll need to adjust the logic here accordingly.
        uint256 token1AmountFromDexA = dexA.swapByRoute(routeA, amount, 0);

        // Now, we'll swap this amount of token1 back to token0 on dexB
        address[] memory routeB = new address[](2);
        routeB[0] = token1;
        routeB[1] = token0;

        require(token1AmountFromDexA > 0, "No tokens after swap 1");

        IERC20(token1).approve(address(dexB), token1AmountFromDexA);

        // Let's determine the amount of token0 we received from dexB after the swap
        uint256 token0AmountFromDexB = dexB.swapByRoute(
            routeB,
            token1AmountFromDexA,
            0
        );

        require(token0AmountFromDexB > 0, "No tokens after swap 2");
        uint bal = IERC20(token0).balanceOf(address(this));
        require(bal >= token0AmountFromDexB, "Balance less than tokens from dex. WTF!");

        // Ensure that the amount we have now (minus the initial borrowed amount) is greater than the fee
        uint repayAmount = amount + fee;
        require(
            token0AmountFromDexB > repayAmount,
            "Arbitrage not profitable; cannot cover flash loan fee"
        );

        // Repay the flash loan
        require(
            IERC20(token0).transfer(pool, repayAmount),
            "Could not transfer tokens"
        );

        // Any remaining tokens (profit) stay in the contract and can be withdrawn by the owner
        uint256 profit = IERC20(token0).balanceOf(address(this));
        require(profit > 0, "No profit made");
        require(IERC20(token0).transfer(owner, profit), "Could not transfer profit to owner");
    }

    // Allows the owner to withdraw any ERC20 tokens from the contract
    function withdrawTokens(address tokenAddress) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(tokenAddress).transfer(owner, balance);
    }

    // If any ETH gets trapped in the contract, this function allows the owner to withdraw it
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner).transfer(balance);
    }
}
