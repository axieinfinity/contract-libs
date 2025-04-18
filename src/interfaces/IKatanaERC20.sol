// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC20 } from "../../dependencies/openzeppelin-4.9.6/contracts/token/ERC20/IERC20.sol";

interface IKatanaERC20 is IERC20 {
  function DOMAIN_SEPARATOR()
    external
    view
    returns (
      // solium-disable-line mixedcase
      bytes32
    );

  function PERMIT_TYPEHASH()
    external
    pure
    returns (
      // solium-disable-line mixedcase
      bytes32
    );

  function nonces(address _owner) external view returns (uint256);

  /**
   * @dev Approves with signature.
   */
  function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s)
    external;
}
