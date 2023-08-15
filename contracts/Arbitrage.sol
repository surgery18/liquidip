// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
        require(
            msg.sender == address(flashLoanProvider),
            "Only the flash loan provider can call this function"
        );

        // First, we'll swap the borrowed amount on dexA for token1
        address[] memory routeA = new address[](2);
        routeA[0] = token0;
        routeA[1] = token1;

        // Here, we're assuming `swapByRoute` is a function in the DEX contract that handles the swap.
        // If not, you'll need to adjust the logic here accordingly.
        dexA.swapByRoute(routeA, amount, 0);

        // Let's determine the amount of token1 we received from dexA
        uint256 token1AmountFromDexA = IERC20(token1).balanceOf(address(this));

        // Now, we'll swap this amount of token1 back to token0 on dexB
        address[] memory routeB = new address[](2);
        routeB[0] = token1;
        routeB[1] = token0;

        dexB.swapByRoute(routeB, token1AmountFromDexA, 0);

        // Let's determine the amount of token0 we received from dexB after the swap
        uint256 token0AmountFromDexB = IERC20(token0).balanceOf(address(this));

        // Ensure that the amount we have now (minus the initial borrowed amount) is greater than the fee
        require(
            token0AmountFromDexB - amount >= fee,
            "Arbitrage not profitable; cannot cover flash loan fee"
        );

        // Repay the flash loan
        flashLoanProvider.repayLoan(token0, amount + fee, pool);

        // Any remaining tokens (profit) stay in the contract and can be withdrawn by the owner
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
