// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed from, address indexed to, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);

    function transfer(address _to, uint _amount) public returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) public returns (bool) {
        require(
            allowance[_from][_to] >= _amount,
            "Not allowed to send this amount"
        );
        _transfer(_from, _to, _amount);
        allowance[_from][_to] -= _amount;
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough tokens");
        //attach spender address to sender
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _amount) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[_from] >= _amount, "Balance of sender is not enough");

        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }
}
