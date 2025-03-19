// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV2V3Interface } from
  "../../../dependencies/chainlink-2.21.0/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import { Math } from "../../../dependencies/openzeppelin-4.9.6/contracts/utils/math/Math.sol";
import { LibPowMath } from "../../math/LibPowMath.sol";

struct ChainlinkPriceFeed {
  AggregatorV2V3Interface _aggregator;
  uint8 _pairDecimal;
  uint8 _tokenInDecimal;
  uint8 _tokenOutDecimal;
  uint64 _maxAcceptableAge;
}

using LibChainlinkPriceFeed for ChainlinkPriceFeed global;

library LibChainlinkPriceFeed {
  using LibPowMath for uint256;

  /// @dev The maximum decimal for the token.
  /// @dev This is used to prevent overflow when scaling the price.
  uint8 internal constant _DECIMAL_LIMIT = 30;
  /// @dev Value of log10(2**256 - 1)
  uint8 internal constant _MAX_DECIMAL = 77;

  /// @dev Thrown when the decimal is larger than the limit decimal.
  error LargeDecimal(uint8 decimal);
  /// @dev Thrown when the price update timestamp is older than the max acceptable age.
  error PriceTooOld(uint256 latestTimestamp, uint256 maxAcceptableTimestamp);
  /// @dev Thrown when the price is negative.
  error PanicNegativeQuotePrice(int256 answer);
  /// @dev Thrown when the computed price is too large.
  error ComputedPriceTooLarge(uint256 price, uint8 priceDecimal, uint8 scaleDecimal);

  /// @dev Emitted when the price feed is updated.
  event ChainlinkPriceFeedUpdated(
    AggregatorV2V3Interface indexed aggregator,
    uint8 pairDecimal,
    uint8 tokenInDecimal,
    uint8 tokenOutDecimal,
    string description
  );
  /// @dev Emitted when the max acceptable age is updated.
  event MaxAcceptableAgeUpdated(AggregatorV2V3Interface indexed aggregator, uint64 maxAcceptableAge);

  /**
   * @dev Sets the price feed for a token.
   * @param $ The Chainlink price feed storage variable.
   * @param aggregator The address of the Chainlink aggregator.
   * @param tokenInDecimal The decimal of token in.
   * @param tokenOutDecimal The decimal of token out.
   * @param maxAcceptableAge The max acceptable age for the price.
   */
  function set(
    ChainlinkPriceFeed storage $,
    address aggregator,
    uint8 tokenInDecimal,
    uint8 tokenOutDecimal,
    uint64 maxAcceptableAge
  ) internal {
    uint8 pairDecimal = AggregatorV2V3Interface(aggregator).decimals();

    if (tokenInDecimal > _DECIMAL_LIMIT) revert LargeDecimal(tokenInDecimal);
    if (tokenOutDecimal > _DECIMAL_LIMIT) revert LargeDecimal(tokenOutDecimal);
    if (pairDecimal > _DECIMAL_LIMIT) revert LargeDecimal(pairDecimal);

    $._aggregator = AggregatorV2V3Interface(aggregator);
    $._tokenInDecimal = tokenInDecimal;
    $._tokenOutDecimal = tokenOutDecimal;
    $._pairDecimal = pairDecimal;
    $._maxAcceptableAge = maxAcceptableAge;

    emit ChainlinkPriceFeedUpdated(
      AggregatorV2V3Interface(aggregator),
      pairDecimal,
      tokenInDecimal,
      tokenOutDecimal,
      AggregatorV2V3Interface(aggregator).description()
    );

    emit MaxAcceptableAgeUpdated(AggregatorV2V3Interface(aggregator), maxAcceptableAge);
  }

  /**
   * @dev Sets the max acceptable age for the price.
   * @param $ The Chainlink price feed storage variable.
   * @param maxAcceptableAge The max acceptable age for the price.
   */
  function setMaxAcceptableAge(ChainlinkPriceFeed storage $, uint64 maxAcceptableAge) internal {
    $._maxAcceptableAge = maxAcceptableAge;

    emit MaxAcceptableAgeUpdated(AggregatorV2V3Interface($._aggregator), maxAcceptableAge);
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
    uint256 scaledPrice = scalePrice(price, priceFeed._pairDecimal, priceFeed._tokenOutDecimal);

    tokenOutAmount = Math.mulDiv(scaledPrice, tokenInAmount, 10 ** priceFeed._tokenInDecimal);
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
    uint256 inversedPrice = inverseAndScalePrice(price, priceFeed._pairDecimal, priceFeed._tokenInDecimal);

    tokenInAmount = Math.mulDiv(inversedPrice, tokenOutAmount, 10 ** priceFeed._tokenOutDecimal);
  }

  /**
   * @dev Get the price from the Chainlink price feed.
   * @param priceFeed The Chainlink price feed.
   * @return price The price in the given decimal.
   */
  function quotePrice(ChainlinkPriceFeed memory priceFeed) internal view returns (uint256 price) {
    (, int256 answer,, uint256 updatedAt,) = priceFeed._aggregator.latestRoundData();
    if (updatedAt < block.timestamp - priceFeed._maxAcceptableAge) {
      revert PriceTooOld(updatedAt, block.timestamp - priceFeed._maxAcceptableAge);
    }
    if (answer <= 0) revert PanicNegativeQuotePrice(answer);

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
    uint256 abs = priceDecimal > scaleDecimal ? priceDecimal - scaleDecimal : scaleDecimal - priceDecimal;
    if (Math.log10(price) + abs > _MAX_DECIMAL) revert ComputedPriceTooLarge(price, priceDecimal, scaleDecimal);

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
