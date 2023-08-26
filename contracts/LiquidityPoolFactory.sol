// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityPool.sol";

contract LiquidityPoolFactory {
    address[] public tokens;
    mapping(address => uint) public tokenIndex;

    mapping(address => mapping(address => address)) public pools;
    mapping(address => address[]) public tokenToPools;
    address[][] public allPairs;

    mapping(uint => address) public allPools;
    uint public poolCount = 0;

    event LiquidityPoolCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pool
    );

    function createLiquidityPool(address tokenA, address tokenB) external {
        require(tokenA != tokenB, "Tokens must be different");
        require(!hasPool(tokenA, tokenB), "Pool already exists");

        address newPool = address(new LiquidityPool(tokenA, tokenB));
        pools[tokenA][tokenB] = newPool;
        pools[tokenB][tokenA] = newPool;
        tokenToPools[tokenA].push(newPool);
        tokenToPools[tokenB].push(newPool);
        allPools[poolCount] = newPool;
        poolCount += 1;
        address[] memory pair = new address[](2);
        pair[0] = tokenA;
        pair[1] = tokenB;
        allPairs.push(pair);

        if (!tokenExists(tokenA)) {
            addToken(tokenA);
        }

        if (!tokenExists(tokenB)) {
            addToken(tokenB);
        }

        emit LiquidityPoolCreated(tokenA, tokenB, newPool);
    }

    function getLiquidityPool(
        address tokenA,
        address tokenB
    ) external view returns (address) {
        return pools[tokenA][tokenB];
    }

    function addToken(address token) internal {
        require(!tokenExists(token), "Token already exists");
        tokens.push(token);
        tokenIndex[token] = tokens.length - 1;
    }

    function tokenExists(address token) internal view returns (bool) {
        return
            tokenIndex[token] > 0 ||
            (tokenIndex[token] == 0 && tokens.length > 0 && tokens[0] == token);
    }

    function hasPool(
        address tokenA,
        address tokenB
    ) public view returns (bool) {
        return pools[tokenA][tokenB] != address(0);
    }

    function getTokensCount() public view returns (uint256) {
        return tokens.length;
    }

    function getPairsCount() public view returns (uint256) {
        return allPairs.length;
    }

    function getAllPairings() external view returns (address[][] memory) {
        return allPairs;
    }

    function getAllTokens() external view returns (address[] memory _tokens) {
        _tokens = new address[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            _tokens[i] = tokens[i];
        }
    }

    function getAllPools() external view returns (address[] memory _pools) {
        _pools = new address[](poolCount);

        for (uint i = 0; i < poolCount; i++) {
            _pools[i] = allPools[i];
        }
    }

    function getTokenPools(
        address token
    ) public view returns (address[] memory) {
        return tokenToPools[token];
    }
}
