// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { LibErrorHandler } from "../LibErrorHandler.sol";

using { toAmount } for Gas global;

enum Gas {
  Strictly,
  NoGriefing,
  ForwardAll,
  NoStorageWrite
}

/// @dev see: https://github.com/axieinfinity/ronin-dpos-contracts/pull/195
uint256 constant GAS_STIPEND_STRICT = 0;

/// @dev Suggested gas stipend for contract receiving NATIVE
/// that disallows any storage writes.
uint256 constant GAS_STIPEND_NO_STORAGE_WRITES = 2_300;

/// @dev Suggested gas stipend for contract receiving NATIVE to perform a few
/// storage reads and writes, but low enough to prevent griefing.
/// Multiply by a small constant (e.g. 2), if needed.
uint256 constant GAS_STIPEND_NO_GRIEF = 100_000;

function toAmount(Gas gas) view returns (uint256) {
  if (gas == Gas.ForwardAll) return gasleft();
  if (gas == Gas.NoGriefing) return GAS_STIPEND_NO_GRIEF;
  if (gas == Gas.NoStorageWrite) return GAS_STIPEND_NO_STORAGE_WRITES;
  return GAS_STIPEND_STRICT;
}

/**
 * @title NativeTransferHelper
 */
library LibNativeTransfer {
  using Strings for *;
  using LibErrorHandler for bool;

  /**
   * @dev Transfers Native Coin and wraps result for the method caller to a recipient.
   */
  function safeTransfer(address to, uint256 value, Gas gas) internal {
    (bool success, bytes memory returnOrRevertData) = trySendValue(to, value, gas.toAmount());
    success.handleRevert(bytes4(0x0), returnOrRevertData);
  }

  /**
   * @dev Unsafe send `amount` Native to the address `to`. If the sender's balance is insufficient,
   * the call does not revert.
   *
   * Note:
   * - Does not assert whether the balance of sender is sufficient.
   * - Does not assert whether the recipient accepts NATIVE.
   * - Consider using `ReentrancyGuard` before calling this function.
   *
   */
  function trySendValue(address to, uint256 value, uint256 gasAmount)
    internal
    returns (bool success, bytes memory returnOrRevertData)
  {
    (success, returnOrRevertData) = to.call{ value: value, gas: gasAmount }("");
  }
}
