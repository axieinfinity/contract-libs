// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IKatanaFactory {
  /**
   * @dev Emitted when a pair for `_token0` token and `_token1` token is created.
   */
  event PairCreated(address indexed _token0, address indexed _token1, address _pair, uint256 _allPairsLength);

  /**
   * @dev Emitted when pair implement is changed from `_old` to `_new`.
   */
  event PairProxyUpdated(address indexed _new, address indexed _old);

  function INIT_CODE_PAIR_HASH() external view returns (bytes32);

  /**
   * @dev Flag whether allowed all users to call.
   */
  function allowedAll() external view returns (address);

  /**
   * @dev Set allowed all.
   *
   * Requirements:
   *
   * - The method caller is admin.
   *
   */
  function setAllowedAll(bool) external;

  /**
   * @dev Returns implementation address for pair token.
   */
  function pairImplementation() external view returns (address);

  /**
   * @dev Set implementation address for all pairs.
   *
   * Requirements:
   *
   * - The method caller is admin.
   *
   * Emit a {PairProxyUpdated} event.
   */
  function setPairImplementation(address) external;

  /**
   * @dev Returns treasury address.
   */
  function treasury() external view returns (address);

  /**
   * @dev Sets treasury address.
   *
   * Requirements:
   *
   * - The method caller is admin.
   *
   */
  function setTreasury(address _treasury) external;

  /**
   * @dev Returns pair address for `_tokenA` and `_tokenB`.
   */
  function getPair(address _tokenA, address _tokenB) external view returns (address _pair);

  /**
   * @dev Returns pair address at `_index` position.
   */
  function allPairs(uint256 _index) external view returns (address _pair);

  /**
   * @dev Returns all pairs length.
   */
  function allPairsLength() external view returns (uint256);

  /**
   * @dev Create pair.
   *
   * Requirements:
   *
   * - The default method caller is contract admin.
   * - All addresses is allowed if `allowedAll` is true.
   *
   */
  function createPair(address _tokenA, address _tokenB) external returns (address _pair);
}
