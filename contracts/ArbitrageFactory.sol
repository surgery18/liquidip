// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Arbitrage.sol";

contract ArbitrageFactory {
    mapping(address => address[]) private userArbitrages;

    function createArbitrage(
        address _dexA,
        address _dexB,
        address _flashLoanProvider,
        address _token0,
        address _token1
    ) external {
        Arbitrage arb = new Arbitrage(
            _dexA,
            _dexB,
            _flashLoanProvider,
            _token0,
            _token1
        );
        userArbitrages[msg.sender].push(address(arb));
    }

    //use these helper functions
    function getUserArbitrages(
        address _user
    ) external view returns (address[] memory) {
        return userArbitrages[_user];
    }

    function getUserArbitragesCount(
        address _user
    ) external view returns (uint) {
        return userArbitrages[_user].length;
    }

    function getUserArbitrageByIndex(
        address _user,
        uint index
    ) external view returns (address) {
        require(index >= 0, "Index cannot be below 0");
        require(index <= userArbitrages[_user].length, "Index out of range");
        return userArbitrages[_user][index];
    }
}
