// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0 || ^0.8.0;

/**
 * Interface for the arbitrage contract
 */
interface IFlashArbitrage {
   function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns(bytes32);
   function flashBorrow(address token, uint256 amount, address[] calldata path) external;
   function approveRepayment(address token, uint256 amount) external;
   function lender() external returns(address);
   function router() external returns(address);
}