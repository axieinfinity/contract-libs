// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV2V3Interface } from
  "../../../dependencies/chainlink-2.21.0/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import { Math } from "../../../dependencies/openzeppelin-4.9.6/contracts/utils/math/Math.sol";
import { LibPowMath } from "../../math/LibPowMath.sol";

struct ChainlinkPriceFeed {
  AggregatorV2V3Interface aggregator;
  uint8 pairDecimal;
  uint8 tokenInDecimal;
  uint8 tokenOutDecimal;
  uint64 maxAcceptableAge;
}

using LibChainlinkPriceFeed for ChainlinkPriceFeed global;

library LibChainlinkPriceFeed {
  using LibPowMath for uint256;

  /// @dev The maximum decimal for the token.
  /// @dev This is used to prevent overflow when scaling the price.
  uint8 internal constant _MAX_DECIMALS = 30;

  /// @dev Thrown when the decimal is larger than the maximum decimal.
  error LargeDecimal(uint8 decimal);
  /// @dev Thrown when the price update timestamp is older than the max acceptable age.
  error ExceededMaxAcceptableAge(uint256 latestTimestamp, uint256 maxAcceptableTimestamp);

  /// @dev Emitted when the price feed is updated.
  event ChainlinkPriceFeedUpdated(
    AggregatorV2V3Interface indexed aggregator,
    uint8 tokenInDecimal,
    uint8 tokenOutDecimal,
    uint64 maxAcceptableAge,
    string description
  );

  /**
   * @dev Sets the price feed for a token.
   * @param $priceFeed The Chainlink price feed storage variable.
   * @param aggregator The address of the Chainlink aggregator.
   * @param tokenInDecimal The decimal of token in.
   * @param tokenOutDecimal The decimal of token out.
   * @param maxAcceptableAge The max acceptable age for the price.
   */
  function set(
    ChainlinkPriceFeed storage $priceFeed,
    address aggregator,
    uint8 tokenInDecimal,
    uint8 tokenOutDecimal,
    uint64 maxAcceptableAge
  ) internal {
    if (tokenInDecimal > _MAX_DECIMALS) revert LargeDecimal(tokenInDecimal);
    if (tokenOutDecimal > _MAX_DECIMALS) revert LargeDecimal(tokenOutDecimal);

    $priceFeed.aggregator = AggregatorV2V3Interface(aggregator);
    $priceFeed.tokenInDecimal = tokenInDecimal;
    $priceFeed.tokenOutDecimal = tokenOutDecimal;
    $priceFeed.pairDecimal = AggregatorV2V3Interface(aggregator).decimals();
    $priceFeed.maxAcceptableAge = maxAcceptableAge;

    emit ChainlinkPriceFeedUpdated(
      AggregatorV2V3Interface(aggregator),
      tokenInDecimal,
      tokenOutDecimal,
      maxAcceptableAge,
      AggregatorV2V3Interface(aggregator).description()
    );
  }

  /**
   * @dev Convert tokenIn amount to tokenOut amount.
   * @param priceFeed The Chainlink price feed struct.
   * @param tokenInAmount The amount of tokenIn.
   * @return tokenOutAmount The amount of tokenOut.
   */
  function convertTokenIn2TokenOut(ChainlinkPriceFeed memory priceFeed, uint256 tokenInAmount)
    internal
    view
    returns (uint256 tokenOutAmount)
  {
    uint256 price = quotePrice(priceFeed);

    // Scale the price to the same decimal as tokenOut
    uint256 scaledPrice = scalePrice(price, priceFeed.pairDecimal, priceFeed.tokenOutDecimal);

    tokenOutAmount = Math.mulDiv(scaledPrice, tokenInAmount, 10 ** priceFeed.tokenInDecimal);
  }

  /**
   * @dev Converts the token out into token in.
   * @param priceFeed The Chainlink price feed struct.
   * @param tokenOutAmount The amount of token out amount.
   * @return tokenInAmount The amount of token in amount.
   */
  function convertTokenOut2TokenIn(ChainlinkPriceFeed memory priceFeed, uint256 tokenOutAmount)
    internal
    view
    returns (uint256 tokenInAmount)
  {
    uint256 price = quotePrice(priceFeed);

    // Scale the price to the same decimal as tokenIn
    // The price is in tokenOut, so we need to inverseAndScalePrice it to get the tokenIn price
    uint256 inversedPrice = inverseAndScalePrice(price, priceFeed.pairDecimal, priceFeed.tokenInDecimal);

    tokenInAmount = Math.mulDiv(inversedPrice, tokenOutAmount, 10 ** priceFeed.tokenOutDecimal);
  }

  /**
   * @dev Get the price from the Chainlink price feed.
   * @param priceFeed The Chainlink price feed.
   * @return price The price in the given decimal.
   */
  function quotePrice(ChainlinkPriceFeed memory priceFeed) internal view returns (uint256 price) {
    (, int256 answer,, uint256 updatedAt,) = priceFeed.aggregator.latestRoundData();
    if (updatedAt < block.timestamp - priceFeed.maxAcceptableAge) {
      revert ExceededMaxAcceptableAge(updatedAt, block.timestamp - priceFeed.maxAcceptableAge);
    }

    return uint256(answer);
  }

  /**
   * @dev Scale the price to the given decimal.
   * @param price The price in the given decimal.
   * @param priceDecimal The decimal of the price.
   * @param scaleDecimal The decimal to scale the price to.
   * @return scaledPrice The scaled price in the given decimal.
   */
  function scalePrice(uint256 price, uint8 priceDecimal, uint8 scaleDecimal)
    internal
    pure
    returns (uint256 scaledPrice)
  {
    return price.exp10(int8(scaleDecimal) - int8(priceDecimal));
  }

  /**
   * @dev Inverse the price of (A/B) to (B/A) and scale it to the given decimal.
   * @param price The price of (A/B) in the given decimal.
   * @param priceDecimal The decimal of the price.
   * @param scaleDecimal The decimal to scale the price to.
   * @return inversedPrice The price of (B/A) scaled in the given decimal.
   */
  function inverseAndScalePrice(uint256 price, uint8 priceDecimal, uint8 scaleDecimal)
    internal
    pure
    returns (uint256 inversedPrice)
  {
    return Math.mulDiv(10 ** priceDecimal, 10 ** scaleDecimal, price);
  }
}
