// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TransferFromHelper
 * @dev Wraps transfer from methods for ERC20 tokens that do not consistently return true/false or revert.
 */
library TransferFromHelper {
  /**
   * @dev Transfers token and wraps result for the input address to a recipient.
   */
  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(
        0x23b872dd, // IERC20.transferFrom.selector
        from,
        to,
        value
      )
    );

    if (!success || !(data.length == 0 || abi.decode(data, (bool)))) {
      revert(
        string.concat(
          "TransferFromHelper: could not transfer token ",
          Strings.toHexString(uint160(token), 20),
          " from ",
          Strings.toHexString(uint160(from), 20),
          " to ",
          Strings.toHexString(uint160(to), 20),
          " value ",
          Strings.toHexString(value)
        )
      );
    }
  }
}
