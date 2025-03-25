// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IWRON } from "../../interfaces/IWRON.sol";
import { IWRONHelper } from "../../interfaces/IWRONHelper.sol";
import { LibNativeTransfer } from "../LibNativeTransfer.sol";
import { LibTransferFromHelper } from "../LibTransferFromHelper.sol";
import { LibTransferHelper } from "../LibTransferHelper.sol";

contract UnwrapTokenAndTransferHelpers {
  using LibTransferFromHelper for address;
  using LibTransferHelper for address;
  using LibNativeTransfer for address payable;

  error InvalidSender();
  error InvalidLength();
  error TotalValueNotMatch();

  IWRON internal immutable i_WRON;
  IWRONHelper internal immutable i_WRON_HELPER;

  constructor(address wron, address wronHelper) {
    i_WRON = IWRON(wron);
    i_WRON_HELPER = IWRONHelper(wronHelper);
  }

  /// @dev Only accept native from WRON_HELPER.
  receive() external payable virtual {
    _requireOnlyWRONHelper();
  }

  modifier validLength(address payable[] memory recipients, uint256[] memory values) {
    _requireLengthValid(recipients, values);
    _;
  }

  /// @dev Return the WRON contract address.
  function getWRON() external view returns (IWRON) {
    return i_WRON;
  }

  /// @dev Return the WRON helper contract address.
  function getWRONHelper() external view returns (IWRONHelper) {
    return i_WRON_HELPER;
  }

  /// @dev Revert if the length of `recipients` and `values` are not the same, and the length is not zero.
  function _requireLengthValid(address payable[] memory recipients, uint256[] memory values) internal pure {
    uint256 length = recipients.length;
    require(length > 0 && length == values.length, InvalidLength());
  }

  /// @dev Revert if the sender is not WRON_HELPER.
  function _requireOnlyWRONHelper() internal view {
    require(msg.sender == address(i_WRON_HELPER), InvalidSender());
  }

  /// @dev Check if the token is WRON.
  function _isWrappedToken(address token) internal view returns (bool) {
    return token == address(i_WRON);
  }

  /**
   * @dev Unwrap the WRON token.
   * - Skip if the payment token is not WRON.
   * - Skip if the zero value.
   */
  function _tryUnwrap(address paymentToken, uint256 value) internal returns (bool) {
    if (!_isWrappedToken(paymentToken)) return false;
    if (value == 0) return false;

    i_WRON.approve(address(i_WRON_HELPER), value);
    i_WRON_HELPER.withdraw(value);
    return true;
  }

  /**
   * @dev Unwrap the WRON token from `from`.
   * - Skip if the payment token is not WRON.
   * - Skip if the zero value.
   */
  function _tryUnwrapFrom(address paymentToken, address from, uint256 value) internal returns (bool) {
    if (!_isWrappedToken(paymentToken)) return false;
    if (value == 0) return false;

    paymentToken.safeTransferFrom({ from: from, to: address(this), value: value });
    i_WRON.approve(address(i_WRON_HELPER), value);
    i_WRON_HELPER.withdraw(value);
    return true;
  }

  /**
   * @dev Unwrap the WRON token and batch transfer RON to the recipients.
   * - If the payment token is not WRON, it will transfer the payment token to `recipients`.
   * - It requires this contract should hold `paymentToken` to transfer.
   */
  function _unwrapOnceAndBatchTransfer(
    address paymentToken,
    uint256 total,
    address payable[] memory recipients,
    uint256[] memory values
  ) internal validLength(recipients, values) {
    bool unwrapped = _tryUnwrap({ paymentToken: paymentToken, value: total });

    uint256 length = recipients.length;
    uint256 sumValues;
    for (uint256 i; i < length; ++i) {
      if (values[i] == 0) continue;

      if (unwrapped) {
        recipients[i].safeTransfer(values[i]);
      } else {
        paymentToken.safeTransfer({ to: recipients[i], value: values[i] });
      }

      sumValues += values[i];
    }

    require(total == sumValues, TotalValueNotMatch());
  }

  /**
   * @dev Unwrap the WRON token from `from` and batch transfer RON to the recipients.
   * - If the payment token is not WRON, it will transfer the payment token from `from` to `recipients`.
   * - It requires this contract should have enough allowance of `from` to transfer `paymentToken`.
   */
  function _unwrapOnceAndBatchTransferFrom(
    address paymentToken,
    address from,
    uint256 total,
    address payable[] memory recipients,
    uint256[] memory values
  ) internal validLength(recipients, values) {
    bool unwrapped = _tryUnwrapFrom({ paymentToken: paymentToken, from: from, value: total });
    uint256 length = recipients.length;
    uint256 sumValues;
    for (uint256 i; i < length; ++i) {
      if (values[i] == 0) continue;

      if (unwrapped) {
        recipients[i].safeTransfer(values[i]);
      } else {
        paymentToken.safeTransferFrom({ from: from, to: recipients[i], value: values[i] });
      }

      sumValues += values[i];
    }

    require(total == sumValues, TotalValueNotMatch());
  }
}
