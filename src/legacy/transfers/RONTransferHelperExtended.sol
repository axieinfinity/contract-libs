// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IWRON.sol";
import "../../interfaces/IWRONHelper.sol";
import "./RONTransferHelper.sol";
import "./TransferFromHelper.sol";
import "./TransferHelper.sol";

library RONTransferHelperExtended {
  /**
   * @dev Safely unwraps tokens if it is WRON token and transfers them to a specified recipient.
   * @param _wron Address of the WRON contract.
   * @param _token Address of the ERC20 token to unwrap and transfer.
   * @param _to Address of the recipient to transfer the tokens to.
   * @param _amount Amount of tokens to transfer.
   *
   * Note: This function may cause a revert if the consumer contract is a proxy, consider using the method
   * `safeUnwrapTokenAndTransferWithHelper` instead.
   */
  function safeUnwrapTokenAndTransfer(IWRON _wron, address _token, address payable _to, uint256 _amount) internal {
    if (_token == address(_wron)) {
      // Check whether the recipient receives RON
      if (RONTransferHelper.send(_to, 0)) {
        _wron.withdraw(_amount);
        RONTransferHelper.safeTransfer(_to, _amount);
        return;
      }
    }

    TransferHelper.safeTransfer(_token, _to, _amount);
  }

  /**
   * @dev See `safeUnwrapTokenAndTransfer`.
   *
   * Requirements:
   * - The consumer contract must approve the contract `_wronHelper`.
   *
   * Note: This function supports the use of a proxy contract by using the WRONHelper contract to unwrap WRON and
   * transfer RON.
   */
  function safeUnwrapTokenAndTransferWithHelper(
    IWRON _wron,
    IWRONHelper _wronHelper,
    address _token,
    address payable _to,
    uint256 _amount
  ) internal {
    if (_token == address(_wron)) {
      // Check whether the recipient receives RON
      if (RONTransferHelper.send(_to, 0)) {
        _wron.approve(address(_wronHelper), _amount);
        _wronHelper.withdrawTo(_to, _amount);
        return;
      }
    }

    TransferHelper.safeTransfer(_token, _to, _amount);
  }

  /**
   * @dev Safely unwraps tokens if it is WRON token from specified sender, and transfers them to a specified recipient.
   * @param _wron Address of the WRON contract.
   * @param _token Address of the ERC20 token to unwrap and transfer.
   * @param _from Address of the sender on whose behalf the tokens will be unwrapped and transferred.
   * @param _to Address of the recipient to transfer the tokens to.
   * @param _amount Amount of tokens to transfer.
   *
   * Note: This function may cause a revert if the consumer contract is a proxy, consider using the method
   * `safeUnwrapTokenAndTransferFromWithHelper` instead.
   */
  function safeUnwrapTokenAndTransferFrom(
    IWRON _wron,
    address _token,
    address _from,
    address payable _to,
    uint256 _amount
  ) internal {
    if (_token == address(_wron)) {
      // Check whether the recipient receives RON
      if (RONTransferHelper.send(_to, 0)) {
        TransferFromHelper.safeTransferFrom(_token, _from, address(this), _amount);
        IWRON(_wron).withdraw(_amount);
        RONTransferHelper.safeTransfer(_to, _amount);
        return;
      }
    }

    TransferFromHelper.safeTransferFrom(_token, _from, _to, _amount);
  }

  /**
   * @dev See `safeUnwrapTokenAndTransfer`.
   *
   * Requirements:
   * - The consumer contract must approve the contract `_wronHelper`.
   *
   * Note: This function supports the use of a proxy contract by using the WRONHelper contract to unwrap WRON and
   * transfer RON.
   */
  function safeUnwrapTokenAndTransferFromWithHelper(
    IWRON _wron,
    IWRONHelper _wronHelper,
    address _token,
    address _from,
    address payable _to,
    uint256 _amount
  ) internal {
    if (_token == address(_wron)) {
      // Check whether the recipient receives RON
      if (RONTransferHelper.send(_to, 0)) {
        TransferFromHelper.safeTransferFrom(_token, _from, address(this), _amount);
        _wron.approve(address(_wronHelper), _amount);
        _wronHelper.withdrawTo(_to, _amount);
        return;
      }
    }

    TransferFromHelper.safeTransferFrom(_token, _from, _to, _amount);
  }
}
