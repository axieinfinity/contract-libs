// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ChainlinkPriceFeed } from "./LibChainlinkPriceFeed.sol";

abstract contract ChainlinkPriceFeedConsumer {
  /// @dev Value is equal to keccak256(abi.encode(uint256(keccak256("ronin.lib.storage.ChainlinkPriceFeedConsumer")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant $$_PriceFeedStorageLocation =
    0xb81636ce02fbbb9f00eddb5b6bbc4ea535be42b2bde99d5f1ee576635dbe3600;

  /// @custom:storage-location erc7201:ronin.lib.storage.ChainlinkPriceFeedConsumer
  struct ChainlinkPriceFeedConsumerStorage {
    ChainlinkPriceFeed _priceFeed;
  }

  /**
   * @dev Updates the Chainlink price feed data.
   */
  function _updatePriceFeed(address aggregator, uint8 tokenInDecimal, uint8 tokenOutDecimal, uint64 maxAcceptableAge)
    internal
  {
    ChainlinkPriceFeed storage $ = _getPriceFeedStorage()._priceFeed;
    $.set(aggregator, tokenInDecimal, tokenOutDecimal, maxAcceptableAge);
  }

  /**
   * @dev Updates the Chainlink price feed max acceptable age for querying price.
   */
  function _updateMaxAcceptableAge(uint64 maxAcceptableAge) internal {
    ChainlinkPriceFeed storage $ = _getPriceFeedStorage()._priceFeed;
    $.setMaxAcceptableAge(maxAcceptableAge);
  }

  /**
   * @dev Returns the Chainlink price feed read-only.
   */
  function _getPriceFeed() internal view returns (ChainlinkPriceFeed memory priceFeed) {
    ChainlinkPriceFeed storage $ = _getPriceFeedStorage()._priceFeed;
    return $;
  }

  /**
   * @dev Returns the Chainlink price feed storage variable.
   */
  function _getPriceFeedStorage() private pure returns (ChainlinkPriceFeedConsumerStorage storage $) {
    assembly ("memory-safe") {
      $.slot := $$_PriceFeedStorageLocation
    }
  }
}
