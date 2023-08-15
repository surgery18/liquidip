// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFlashLoanReceiver {
    function executeFlashloan(
        address token,
        uint256 amount,
        uint256 fee,
        address pool
    ) external;
}
