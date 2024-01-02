// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TransferHelper
 * @dev Wraps transfer methods for ERC20/native tokens that do not consistently return true/false or revert.
 */
library TransferHelper {
  /**
   * @dev Transfers token and wraps result for the method caller to a recipient.
   */
  function safeTransfer(address _token, address _to, uint256 _value) internal {
    (bool success, bytes memory data) = _token.call(
      abi.encodeWithSelector(
        0xa9059cbb, // IERC20.transfer.selector
        _to,
        _value
      )
    );

    if (!success || !(data.length == 0 || abi.decode(data, (bool)))) {
      revert(
        string(
          abi.encodePacked(
            "TransferHelper: could not transfer token ",
            Strings.toHexString(uint160(_token), 20),
            " to ",
            Strings.toHexString(uint160(_to), 20),
            " value ",
            Strings.toHexString(_value)
          )
        )
      );
    }
  }
}
