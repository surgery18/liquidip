// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AggregatorV3InterfaceMock {
    function description() external pure returns (string memory) {
        return "BNB / USD";
    }

    function version() external pure returns (uint256) {
        return 4;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        pure
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, 0, 0, 0, 0);
    }

    function latestRoundData()
        external
        pure
        returns (
            uint80,
            int256 answer,
            uint256,
            uint256,
            uint80
        )
    {
        return (0, int256(41323 * 10**6), 0, 0, 0);
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }
}
