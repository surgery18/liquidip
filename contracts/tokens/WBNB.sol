// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Very basic token contract for a Wrapped Eth (or BNB in my case)
*/

import "../ERC20.sol";

contract WBNB is ERC20 {
    string public name = "Wrapped BNB";
    string public symbol = "WBNB";
    uint8 public decimals = 18;

    event Deposit(address indexed to, uint amount);
    event Withdrawal(address indexed to, uint amount);

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) public {
        require(
            balanceOf[msg.sender] >= _amount,
            "You don't have enough tokens to withdraw!"
        );
        balanceOf[msg.sender] -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Funds were not sent");
        emit Withdrawal(msg.sender, _amount);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }
}
