// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "../../dependencies/openzeppelin-4.9.6/contracts/utils/Strings.sol";
import { IERC20 } from "../../dependencies/openzeppelin-4.9.6/contracts/token/ERC20/IERC20.sol";
import { LibErrorHandler } from "../LibErrorHandler.sol";

/**
 * @title TransferFromHelper
 * @dev Wraps transfer from methods for ERC20 tokens that do not consistently return true/false or revert.
 */
library LibTransferFromHelper {
  using LibErrorHandler for bool;

  /**
   * @dev Transfers token and wraps result for the input address to a recipient.
   */
  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    bytes4 selector = IERC20.transferFrom.selector;
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(selector, from, to, value));

    success.handleRevert(selector, data);
  }
}
