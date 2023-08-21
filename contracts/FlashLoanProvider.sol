// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityPool.sol";
import "./LiquidityPoolFactory.sol";
import "./IERC20.sol";

contract FlashLoanProvider {
    LiquidityPoolFactory public factory;

    constructor(address _factory) {
        factory = LiquidityPoolFactory(_factory);
    }

    function requestFlashLoan(address desiredToken, uint amount) external {
        address pool = findOptimalPool(desiredToken, amount);
        require(pool != address(0), "No suitable pool found");
        LiquidityPool(pool).flashLoan(msg.sender, desiredToken, amount);
    }

    function findOptimalPool(
        address desiredToken,
        uint amount
    ) internal view returns (address) {
        address[] memory pools = factory.getTokenPools(desiredToken);
        if (pools.length == 0) return address(0);
        for (uint i = 0; i < pools.length; i++) {
            uint poolBal = IERC20(desiredToken).balanceOf(pools[i]);
            if (poolBal >= amount) {
                return pools[i];
            }
        }
        return address(0);
    }
}
