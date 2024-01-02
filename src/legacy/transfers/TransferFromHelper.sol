// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TransferFromHelper
 * @dev Wraps transfer from methods for ERC20 tokens that do not consistently return true/false or revert.
 */
library TransferFromHelper {
  /**
   * @dev Transfers token and wraps result for the input address to a recipient.
   */
  function safeTransferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _value
  ) internal {
    (bool success, bytes memory data) = _token.call(
      abi.encodeWithSelector(
        0x23b872dd, // IERC20.transferFrom.selector
        _from,
        _to,
        _value
      )
    );

    if (!success || !(data.length == 0 || abi.decode(data, (bool)))) {
      revert(
        string(
          abi.encodePacked(
            "TransferFromHelper: could not transfer token ",
            Strings.toHexString(uint160(_token), 20),
            " from ",
            Strings.toHexString(uint160(_from), 20),
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
