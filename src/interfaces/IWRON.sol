// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWRON {
  /**
   * @dev Deposit RON and increase balance WRON tokens of sender.
   */
  function deposit() external payable;

  /// @dev See {IERC20-transfer}.
  function transfer(address to, uint256 value) external returns (bool);

  /// @dev See {IERC20-transferFrom}.
  function transferFrom(address src, address dst, uint256 wad) external returns (bool);

  /**
   * @dev Withdraw RON and decrease balance WRON tokens of sender.
   */
  function withdraw(uint256) external;

  /// @dev See {IERC20-balanceOf}.
  function balanceOf(address) external view returns (uint256);

  /// @dev See {IERC20-approve}.
  function approve(address guy, uint256 wad) external returns (bool);
}
