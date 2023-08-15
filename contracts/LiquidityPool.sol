// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ERC20.sol";
import "./IFlashLoanReceiver.sol";

contract LiquidityPool is ERC20 {
    IERC20 public token0;
    IERC20 public token1;

    string public constant name = "Liquidity Pool Token";
    string public constant symbol = "LPT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    event LiquidityAdded(address indexed user, uint256 amount);
    event LiquidityRemoved(address indexed user, uint256 lpAmount);
    event TokensSwapped(
        address indexed user,
        uint256 amountIn,
        uint256 amountOut
    );

    event FlashLoan(
        address indexed borrower,
        address indexed token,
        uint amount,
        uint fee
    );

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function addLiquidity(uint amountToken0, uint amountToken1) external {
        require(
            amountToken0 > 0 && amountToken1 > 0,
            "Amounts must be greater than 0"
        );
        require(
            token0.transferFrom(msg.sender, address(this), amountToken0),
            "Token0 transfer failed"
        );
        require(
            token1.transferFrom(msg.sender, address(this), amountToken1),
            "Token1 transfer failed"
        );
        uint totalLiquidity = totalSupply == 0
            ? sqrt(amountToken0 * amountToken1)
            : totalSupply;
        _mint(msg.sender, totalLiquidity);
        emit LiquidityAdded(msg.sender, totalLiquidity);
    }

    function removeLiquidity(uint256 lpAmount) external {
        _burn(msg.sender, lpAmount);
        uint256 token0Reserve = token0.balanceOf(address(this));
        uint256 token1Reserve = token1.balanceOf(address(this));

        uint256 token0Amount = (lpAmount * token0Reserve) / totalSupply;
        uint256 token1Amount = (lpAmount * token1Reserve) / totalSupply;

        require(token0Amount > 0 && token1Amount > 0, "Insufficient liquidity");
        require(
            token0.transfer(msg.sender, token0Amount),
            "Token transfer failed"
        );
        require(
            token1.transfer(msg.sender, token1Amount),
            "Token transfer failed"
        );
        emit LiquidityRemoved(msg.sender, lpAmount);
    }

    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) external returns (uint) {
        require(
            tokenIn == address(token0) || tokenIn == address(token1),
            "Invalid input token"
        );
        require(
            tokenOut == address(token0) || tokenOut == address(token1),
            "Invalid output token"
        );
        require(
            tokenIn != tokenOut,
            "Input and output tokens must be different"
        );
        require(amountIn > 0, "Amount must be greater than 0");

        uint amountOut = getAmountOut(tokenIn, tokenOut, amountIn);
        require(amountOut > 0, "Amount must be greater than 0");

        if (tokenIn == address(token0)) {
            require(
                token0.transferFrom(msg.sender, address(this), amountIn),
                "Token transfer failed"
            );
            require(
                token1.transfer(msg.sender, amountOut),
                "Token transfer failed"
            );
        } else {
            require(
                token1.transferFrom(msg.sender, address(this), amountIn),
                "Token transfer failed"
            );
            require(
                token0.transfer(msg.sender, amountOut),
                "Token transfer failed"
            );
        }

        emit TokensSwapped(msg.sender, amountIn, amountOut);
        return amountOut;
    }

    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) public view returns (uint) {
        uint tokenInReserve = tokenIn == address(token0)
            ? token0.balanceOf(address(this))
            : token1.balanceOf(address(this));
        uint tokenOutReserve = tokenOut == address(token0)
            ? token0.balanceOf(address(this))
            : token1.balanceOf(address(this));

        uint amountOUtBeforeFee = (amountIn * tokenOutReserve) / tokenInReserve;
        uint feeAmount = (amountOUtBeforeFee * 3) / 1000;
        return amountOUtBeforeFee - feeAmount;
    }

    function flashLoan(address borrower, address token, uint amount) external {
        require(
            token == address(token0) || token == address(token1),
            "Token not in this pool"
        );

        uint balanceBefore = IERC20(token).balanceOf(address(this));
        require(balanceBefore >= amount, "Not enough liquidity in pool");

        uint fee = (amount * 5) / 10000;

        IERC20(token).transfer(borrower, amount);
        IFlashLoanReceiver(borrower).executeFlashloan(
            token,
            amount,
            fee,
            address(this)
        );

        uint balanceAfter = IERC20(token).balanceOf(address(this));
        require(
            balanceAfter == balanceBefore + fee,
            "Flash loan hasn't been repaid with fee"
        );

        emit FlashLoan(borrower, token, amount, fee);
    }

    function _mint(address _to, uint _amount) internal {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint _amount) internal {
        require(
            balanceOf[_from] >= _amount,
            "ERC20: burn amount exceeds balance"
        );
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
        emit Transfer(_from, address(0), _amount);
    }

    // Utility function to calculate square root (for initial liquidity calculation)
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint z = (x + 1) / 2;
        uint y = x;
        while (z < x) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
