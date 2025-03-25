// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "../../dependencies/openzeppelin-4.9.6/contracts/utils/Strings.sol";
import { IERC20 } from "../../dependencies/openzeppelin-4.9.6/contracts/token/ERC20/IERC20.sol";
import { LibErrorHandler } from "../LibErrorHandler.sol";

/**
 * @title LibTransferHelper
 * @dev Wraps transfer methods for ERC20/native tokens that do not consistently return true/false or revert.
 */
library LibTransferHelper {
  using LibErrorHandler for bool;

  /**
   * @dev Transfers token and wraps result for the method caller to a recipient.
   */
  function safeTransfer(address token, address to, uint256 value) internal {
    bytes4 selector = IERC20.transfer.selector;
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(selector, to, value));

    success.handleRevert(selector, data);
  }
}
