// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityPoolFactory.sol";
import "./FlashLoanProvider.sol";
import "./DEX.sol";

contract DEXFactory {
    struct DEXData {
        address dex;
        address flashLoanProvider;
        address liquidityPoolFactory;
    }
    DEXData[] public dexes;

    mapping(address => DEXData) public dexToDetails;

    event DEXCreated(
        address indexed dex,
        address indexed flashLoanProvider,
        address indexed liquidityPoolFactory
    );

    function createDex() external returns (DEXData memory) {
        LiquidityPoolFactory newLPF = new LiquidityPoolFactory();
        DEX newDex = new DEX(address(newLPF));
        FlashLoanProvider newFLP = new FlashLoanProvider(address(newLPF));

        DEXData memory data = DEXData({
            dex: address(newDex),
            flashLoanProvider: address(newFLP),
            liquidityPoolFactory: address(newLPF)
        });

        dexes.push(data);
        dexToDetails[address(newDex)] = data;

        emit DEXCreated(address(newDex), address(newFLP), address(newLPF));
        return data;
    }

    function getDEXCount() external view returns (uint256) {
        return dexes.length;
    }

    function getDEXDetails(
        uint256 index
    )
        external
        view
        returns (
            address dex,
            address flashLoanProvider,
            address liquidityPoolFactory
        )
    {
        require(index < dexes.length, "Index out of bounds");
        return (
            dexes[index].dex,
            dexes[index].flashLoanProvider,
            dexes[index].liquidityPoolFactory
        );
    }

    function getDEXDetailsByAddress(
        address dexAddress
    )
        external
        view
        returns (
            address dex,
            address flashLoanProvider,
            address liquidityPoolFactory
        )
    {
        DEXData memory details = dexToDetails[dexAddress];
        require(details.dex != address(0), "DEX not found");
        return (
            details.dex,
            details.flashLoanProvider,
            details.liquidityPoolFactory
        );
    }

    function getAllDexes() external view returns (DEXData[] memory) {
        return dexes;
    }
}
