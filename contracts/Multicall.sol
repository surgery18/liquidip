// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multicall {
    struct Call {
        address target;
        bytes data;
    }

    struct CallResult {
        bool error;
        bytes result;
    }

    function aggregate(
        Call[] memory _calls
    ) external returns (CallResult[] memory) {
        CallResult[] memory _results = new CallResult[](_calls.length);
        for (uint256 i = 0; i < _calls.length; i++) {
            Call memory _call = _calls[i];
            (bool success, bytes memory data) = _call.target.call(_call.data);
            require(success, string(data));
            _results[i] = CallResult(success, data);
        }

        return _results;
    }
}
