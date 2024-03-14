// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IWRON } from "../../interfaces/IWRON.sol";
import { IWRONHelper } from "../../interfaces/IWRONHelper.sol";
import { RONTransferHelper } from "./RONTransferHelper.sol";
import { TransferFromHelper } from "./TransferFromHelper.sol";
import { TransferHelper } from "./TransferHelper.sol";

library RONTransferHelperExtended {
  /**
   * @dev Safely unwraps tokens if it is WRON token and transfers them to a specified recipient.
   * @param wron Address of the WRON contract.
   * @param token Address of the ERC20 token to unwrap and transfer.
   * @param to Address of the recipient to transfer the tokens to.
   * @param amount Amount of tokens to transfer.
   *
   * Note: This function may cause a revert if the consumer contract is a proxy, consider using the method
   * `safeUnwrapTokenAndTransferWithHelper` instead.
   */
  function safeUnwrapTokenAndTransfer(IWRON wron, address token, address payable to, uint256 amount) internal {
    if (token == address(wron)) {
      // Check whether the recipient receives RON
      if (RONTransferHelper.send(to, 0)) {
        wron.withdraw(amount);
        RONTransferHelper.safeTransfer(to, amount);
        return;
      }
    }

    TransferHelper.safeTransfer(token, to, amount);
  }

  /**
   * @dev See `safeUnwrapTokenAndTransfer`.
   *
   * Requirements:
   * - The consumer contract must approve the contract `wronHelper`.
   *
   * Note: This function supports the use of a proxy contract by using the WRONHelper contract to unwrap WRON and
   * transfer RON.
   */
  function safeUnwrapTokenAndTransferWithHelper(
    IWRON wron,
    IWRONHelper wronHelper,
    address token,
    address payable to,
    uint256 amount
  ) internal {
    if (token == address(wron)) {
      // Check whether the recipient receives RON
      if (RONTransferHelper.send(to, 0)) {
        wron.approve(address(wronHelper), amount);
        wronHelper.withdrawTo(to, amount);
        return;
      }
    }

    TransferHelper.safeTransfer(token, to, amount);
  }

  /**
   * @dev Safely unwraps tokens if it is WRON token from specified sender, and transfers them to a specified recipient.
   * @param wron Address of the WRON contract.
   * @param token Address of the ERC20 token to unwrap and transfer.
   * @param from Address of the sender on whose behalf the tokens will be unwrapped and transferred.
   * @param to Address of the recipient to transfer the tokens to.
   * @param amount Amount of tokens to transfer.
   *
   * Note: This function may cause a revert if the consumer contract is a proxy, consider using the method
   * `safeUnwrapTokenAndTransferFromWithHelper` instead.
   */
  function safeUnwrapTokenAndTransferFrom(IWRON wron, address token, address from, address payable to, uint256 amount)
    internal
  {
    if (token == address(wron)) {
      // Check whether the recipient receives RON
      if (RONTransferHelper.send(to, 0)) {
        TransferFromHelper.safeTransferFrom(token, from, address(this), amount);
        IWRON(wron).withdraw(amount);
        RONTransferHelper.safeTransfer(to, amount);
        return;
      }
    }

    TransferFromHelper.safeTransferFrom(token, from, to, amount);
  }

  /**
   * @dev See `safeUnwrapTokenAndTransfer`.
   *
   * Requirements:
   * - The consumer contract must approve the contract `wronHelper`.
   *
   * Note: This function supports the use of a proxy contract by using the WRONHelper contract to unwrap WRON and
   * transfer RON.
   */
  function safeUnwrapTokenAndTransferFromWithHelper(
    IWRON wron,
    IWRONHelper wronHelper,
    address token,
    address from,
    address payable to,
    uint256 amount
  ) internal {
    if (token == address(wron)) {
      // Check whether the recipient receives RON
      if (RONTransferHelper.send(to, 0)) {
        TransferFromHelper.safeTransferFrom(token, from, address(this), amount);
        wron.approve(address(wronHelper), amount);
        wronHelper.withdrawTo(to, amount);
        return;
      }
    }

    TransferFromHelper.safeTransferFrom(token, from, to, amount);
  }
}
