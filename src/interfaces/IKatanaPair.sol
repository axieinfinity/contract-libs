// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IKatanaERC20 } from "./IKatanaERC20.sol";

interface IKatanaPair is IKatanaERC20 {
  /**
   * @dev Emitted when `_amount0` token0s and `_amount1` token1s is minted for `_sender` address.
   */
  event Mint(address indexed _sender, uint256 _amount0, uint256 _amount1);

  /**
   * @dev Emitted when `_amount0` token0s and `_amount1` token1s is burned from `_sender` address
   * to `_to` address.
   */
  event Burn(address indexed _sender, uint256 _amount0, uint256 _amount1, address indexed _to);

  /**
   * @dev Emitted when `_sender` address swapped `_amount0In` and `_amount1In` tokens for
   * `_amount0In` and `_amount1In` tokens for `_to`.
   */
  event Swap(
    address indexed _sender,
    uint256 _amount0In,
    uint256 _amount1In,
    uint256 _amount0Out,
    uint256 _amount1Out,
    address indexed _to
  );

  /**
   * @dev Emitted when pool is synced.
   */
  event Sync(uint112 _reserve0, uint112 _reserve1);

  /**
   * @dev Initializes once by the factory at time of deployment.
   */
  function initialize(
    address _token0,
    address _token1,
    address _admin,
    string calldata _name,
    string calldata _symbol
  ) external;

  /**
   * @dev Returns pool reserves.
   */
  function getReserves()
    external
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint32 _blockTimestampLast
    );

  /**
   * @dev Mints liquidity for `_to` address after transfered tokens into pool.
   *
   * This low-level function should be called from a contract which performs important safety
   * checks.
   */
  function mint(address _to) external returns (uint256 _liquidity);

  /**
   * @dev Burns liquidity for `_to` address after transfered liquidity into pool.
   *
   * This low-level function should be called from a contract which performs important safety
   * checks.
   */
  function burn(address _to) external returns (uint256 _amount0, uint256 _amount1);

  /**
   * @dev Swaps tokens for `_to` address.
   *
   * This low-level function should be called from a contract which performs important safety
   * checks.
   */
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address _to,
    bytes calldata
  ) external;

  /**
   * @dev Forces reserves to match balances.
   */
  function sync() external;

  /**
   * @dev Forces balances to match reserves.
   *
   * Transfer the remain token balances to `_to` address.
   */
  function skim(address _to) external;
}
