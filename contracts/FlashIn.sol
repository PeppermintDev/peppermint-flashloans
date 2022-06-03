// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./FlashVault.sol";
import "./interfaces/IWETH.sol";

// deployed at 0x074C21FaB7F06c75D18E0d9190f8612Da8b2004b

contract FlashIn {

    FlashVault vault;
    IWETH weth;

    constructor (FlashVault _vault,IWETH _weth) {
        vault = _vault;
        weth = _weth;
    }

    function enterETH() public payable {
        uint amountIn = msg.value;
        weth.deposit{value: amountIn}();
        weth.approve(address(vault),amountIn);
        vault.enter(amountIn);
        vault.transfer(msg.sender,vault.balanceOf(address(this)));
    }
}