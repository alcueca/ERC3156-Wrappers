pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "./PoolAddress.sol";

contract UniswapV3PoolPeriPhery is IUniswapV3MintCallback {

    IUniswapV3Pool public ipool; 
    struct MintCallbackData {
        PoolAddress.PoolKey poolKey;
        address payer;
    }

    function mint(
        address pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) public {
            ipool = IUniswapV3Pool(pool);
            address token0 = ipool.token0();
            address token1 = ipool.token1();
            IERC20(token0).approve(pool, type(uint256).max);
            IERC20(token1).approve(pool, type(uint256).max);

            PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
                token0: token0, 
                token1: token1, 
                fee: 3000
            });

            ipool.mint(
                recipient, 
                tickLower, 
                tickUpper, 
                amount, 
                abi.encode(
                    MintCallbackData({
                        poolKey: poolKey,
                        payer: msg.sender
                    })
                )
            );
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        // CallbackValidation.verifyCallback(factory, decoded.poolKey);

        if (amount0Owed > 0) IERC20(decoded.poolKey.token0).transferFrom(decoded.payer, msg.sender, amount0Owed);
        if (amount1Owed > 0) IERC20(decoded.poolKey.token1).transferFrom(decoded.payer, msg.sender, amount1Owed);
    }

}