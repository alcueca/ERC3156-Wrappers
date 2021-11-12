// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC20.sol";
import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";

contract FlashBorrower is IERC3156FlashBorrower {
    enum Action {NORMAL, STEAL, REENTER}

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    uint256 public flashBalance;
    address public flashSender;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    struct FlashCallbackData {
        uint256 amountOfUSDLToMint;
        address poolForWETHLoan;
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(address sender, address token, uint256 amount, uint256 fee, bytes calldata data) external override returns(bytes32) {
        require(sender == address(this), "FlashBorrower: External loan initiator");
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
        flashSender = sender;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;
        if (action == Action.NORMAL) {
            flashBalance = IERC20(token).balanceOf(address(this));
        } else if (action == Action.STEAL) {
            // do nothing
        } else if (action == Action.REENTER) {
            flashBorrow(IERC3156FlashLender(msg.sender), token, amount * 2);
        }
        return CALLBACK_SUCCESS;
    }

    function flashBorrowForUniswapV3(
        IERC3156FlashLender lender, 
        address token, 
        address poolForWETHLoan,
        uint256 amountOfCollateralToBorrow, 
        uint256 amountOfUSDLToMint
    ) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        approveRepayment(lender, token, amountOfCollateralToBorrow);
        lender.flashLoan(
            IERC3156FlashBorrower(address(this)),
            token, 
            amountOfCollateralToBorrow, 
            abi.encode(
                FlashCallbackData({
                    amountOfUSDLToMint: amountOfUSDLToMint,
                    poolForWETHLoan: poolForWETHLoan
                })
            )
        );
    }

    function flashBorrow(IERC3156FlashLender lender, address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.NORMAL);
        approveRepayment(lender, token, amount);
        lender.flashLoan(this, token, amount, data);
    }

    function flashBorrowAndSteal(IERC3156FlashLender lender, address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.STEAL);
        lender.flashLoan(this, token, amount, data);
    }

    function flashBorrowAndReenter(IERC3156FlashLender lender, address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.REENTER);
        approveRepayment(lender, token, amount);
        lender.flashLoan(this, token, amount, data);
    }

    function approveRepayment(IERC3156FlashLender lender, address token, uint256 amount) public {
        uint256 _allowance = IERC20(token).allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20(token).approve(address(lender), _allowance + _repayment);
    }
}
