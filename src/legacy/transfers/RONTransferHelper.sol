// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title RONTransferHelper
 */
library RONTransferHelper {
  /**
   * @dev Transfers RON and wraps result for the method caller to a recipient.
   */
  function safeTransfer(address payable to, uint256 value) internal {
    bool success = send(to, value);

    if (!success) {
      revert(
        string(
          abi.encodePacked(
            "TransferHelper: could not transfer RON to ",
            Strings.toHexString(uint160(address(to)), 20),
            " value ",
            Strings.toHexString(value)
          )
        )
      );
    }
  }

  /**
   * @dev Returns whether the call was success.
   * Note: this function should use with the `ReentrancyGuard`.
   */
  function send(address payable to, uint256 value) internal returns (bool success) {
    (success,) = to.call{ value: value }(new bytes(0));
  }
}
