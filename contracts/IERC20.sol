// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address sender,
        address spender
    ) external view returns (uint256);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function symbol() external view returns (string memory);
}
