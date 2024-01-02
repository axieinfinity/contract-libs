// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TransferHelper
 * @dev Wraps transfer methods for ERC20/native tokens that do not consistently return true/false or revert.
 */
library TransferHelper {
  /**
   * @dev Transfers token and wraps result for the method caller to a recipient.
   */
  function safeTransfer(address token, address to, uint256 value) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(
        0xa9059cbb, // IERC20.transfer.selector
        to,
        value
      )
    );

    if (!success || !(data.length == 0 || abi.decode(data, (bool)))) {
      revert(
        string.concat(
          "TransferHelper: could not transfer token ",
          Strings.toHexString(uint160(token), 20),
          " to ",
          Strings.toHexString(uint160(to), 20),
          " value ",
          Strings.toHexString(value)
        )
      );
    }
  }
}
