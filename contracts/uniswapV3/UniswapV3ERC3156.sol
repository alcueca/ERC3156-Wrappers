// // SPDX-License-Identifier: GPL-3.0-or-later
// // Derived from https://github.com/Austin-Williams/uniswap-flash-swapper

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";

import "@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3ERC3156 is IERC3156FlashLender, IUniswapV3FlashCallback {
    using SafeMath for uint256;

    // CONSTANTS
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    IUniswapV3Factory public factory;

    // ACCESS CONTROL
    address permissionedPairAddress;

    // DEFAULT TOKENS
    address weth;
    address usdl;

    // fee2 and fee3 are the two other fees associated with the two other pools of token0 and token1
    struct FlashCallbackData {
        uint256 amountOfUSDLToMint;
        address poolForWETHLoan;
    }

    /// @param factory_ Uniswap v3 UniswapV3Factory address
    /// @param weth_ Weth contract used in Uniswap v3 Pairs
    /// @param usdl_ Usdl contract used in Uniswap v3 Pairs
    constructor(IUniswapV3Factory factory_, address weth_, address usdl_) {
        factory = factory_;
        weth = weth_;
        usdl = usdl_;
    }

    /**
     * @dev Get the Uniswap Pair that will be used as the source of a loan. The opposite token will be Weth, except for Weth that will be Dai.
     * @param token The loan currency.
     * @return The Uniswap V3 Pair that will be used as the source of the flash loan.
     */
    function getPairAddress(address token) public view returns (address) {
        address tokenOther = token == weth ? usdl : weth;
        return factory.getPool(token, tokenOther, 3000);
    }

    /**
     * @dev From ERC-3156. The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view override returns (uint256) {
        address pairAddress = getPairAddress(token);
        if (pairAddress != address(0)) {
            uint256 balance = IERC20(token).balanceOf(pairAddress);
            if (balance > 0) return balance - 1;
        }
        return 0;
    }

    /**
     * @dev From ERC-3156. The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(getPairAddress(token) != address(0), "Unsupported currency");
        return ((amount * 3) / 997) + 1;    }

    /**
     * @dev From ERC-3156. Loan `amount` tokens to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param amountOfCollateralToBorrow The amount of tokens lent.
     * @param userData A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amountOfCollateralToBorrow, bytes memory userData) external override returns(bool) {
        address pairAddress = getPairAddress(token);
        require(pairAddress != address(0), "Unsupported currency");

        if (permissionedPairAddress != pairAddress) permissionedPairAddress = pairAddress; // access control

        ( uint256 amountOfUSDLToMint, address poolForWETHLoan ) = abi.decode(userData, (uint256, address)); // Use this to unpack arbitrary data

        IUniswapV3Pool(poolForWETHLoan).flash(
            address(receiver),
            0,
            amountOfCollateralToBorrow,
            abi.encode(
                amountOfUSDLToMint,
                msg.sender,
                receiver,
                token
            )
        );
        return true;
    }

    // Flashswap Callback
    function uniswapV3FlashCallback(
        uint256 fee0, // Fee on Token0 (USDL)
        uint256 fee1, // Fee on Token1 (WETH)
        bytes calldata data
    ) external override {
        // access control
        require(msg.sender == permissionedPairAddress, "only permissioned UniswapV3 pair can call");

        (uint256 amount, IERC3156FlashBorrower receiver, address origin, address token) = abi.decode(data, (uint256, IERC3156FlashBorrower, address, address));
        uint256 fee = flashFee(token, amount);

        bytes memory decoded = abi.encode(
            FlashCallbackData({
                amountOfUSDLToMint: amount,
                poolForWETHLoan: msg.sender
            })
        );

        // // send the borrowed amount to the receiver
        IERC20(token).transfer(address(receiver), amount);
        // // do whatever the user wants
        require(
            receiver.onFlashLoan(
                origin, 
                token, 
                amount, 
                fee,
                decoded
            ) == CALLBACK_SUCCESS,
            "Callback failed"
        );
        // // // retrieve the borrowed amount plus fee from the receiver and send it to the uniswap pair
        IERC20(token).transferFrom(address(receiver), msg.sender, amount.add(fee));
    }
}
