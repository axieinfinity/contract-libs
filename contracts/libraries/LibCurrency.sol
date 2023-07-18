// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

address constant NATIVE = address(0);

library LibCurrency {
  /// @notice returns true if currency is native
  /// @param currency The currency to check
  /// @return yes true if currency is native
  function isNative(address currency) internal pure returns (bool yes) {
    yes = currency == NATIVE;
  }

  /// @notice Get the balance of a currency for account
  /// @param currency The currency to get the balance of
  /// @param account The address to get the balance of
  /// @return balance The balance of the currency for account
  function balanceOf(address currency, address account) internal view returns (uint256 balance) {
    if (isNative(currency)) {
      balance = account.balance;
    } else {
      balance = IERC20(currency).balanceOf(account);
    }
  }
}
