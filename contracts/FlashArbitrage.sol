// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";
import "./interfaces/IUniswapV2Router01.sol";

//["0x53fcf4970BD5341b7eC724f5aB9920F0401687a7","0x7b535379bBAfD9cD12b35D91aDdAbF617Df902B2","0xA1df349a6c6Ec3805d54A9677379ec5c7E8A97b1","0x69a3eDdB6bE2d56E668E7DfF68DB1303e675A0F0","0x53fcf4970BD5341b7eC724f5aB9920F0401687a7"]
contract FlashArbitrage is IERC3156FlashBorrower {

    IERC3156FlashLender public lender = IERC3156FlashLender(0x5C3ff0B8AF2c0b27c06294eEb58032E9b291C71A);
    IUniswapV2Router01 public router;
    address[] public _path;


    constructor (IUniswapV2Router01 _router) {
        router = _router;//0xfd4a9c7957ba1314f2546b0b9ec7cee01ac24cb9
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external override returns(bytes32) {
        require(msg.sender == address(lender), "FlashBorrower: Untrusted lender");
        require(initiator == address(this), "FlashBorrower: External loan initiator");

        IERC20(token).approve(address(router),amount);
        address[] memory path = _path;
        router.swapExactTokensForTokens(
            amount,
            amount,
            path,
            address(this),
            block.timestamp
        );

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function flashBorrow(address token, uint256 amount, address[] calldata path) public {

        _path = path;
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(0);
        approveRepayment(token, amount);
        lender.flashLoan(this, token, amount, data);
        IERC20(token).transfer(msg.sender,IERC20(token).balanceOf(address(this)));
    }

    function approveRepayment(address token, uint256 amount) public {
        uint256 _allowance = IERC20(token).allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20(token).approve(address(lender), _allowance + _repayment);
    }

}
