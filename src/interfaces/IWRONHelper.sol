// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWRONHelper {
  /**
   * @dev Returns WRON address.
   */
  function WRON() external view returns (address);

  /**
   * @dev Deposit WRON and withdraw RON token.
   *
   * Requirements:
   * - This contract must be approved `amount` WRON tokens by sender.
   */
  function withdraw(uint256 amount) external;

  /**
   * @dev Deposit WRON and withdraw RON token to address `to`.
   *
   * Requirements:
   * - This contract must be approved `amount` WRON tokens by sender.
   */
  function withdrawTo(address payable to, uint256 amount) external;
}
