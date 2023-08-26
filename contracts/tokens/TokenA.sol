// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20.sol";

contract TokenA is ERC20 {
    string public constant name = "TokenA";
    string public constant symbol = "TA";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1000000 * 10 ** decimals;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
}
