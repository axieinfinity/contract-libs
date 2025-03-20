// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV2V3Interface } from
  "../../../dependencies/chainlink-2.21.0/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import { Math } from "../../../dependencies/openzeppelin-4.9.6/contracts/utils/math/Math.sol";
import { LibPowMath } from "../../math/LibPowMath.sol";

struct ChainlinkPriceFeed {
  AggregatorV2V3Interface _aggregator;
  uint8 _tokenInDecimal;
  uint8 _tokenOutDecimal;
  uint64 _maxAcceptableAge;
}

using LibChainlinkPriceFeed for ChainlinkPriceFeed global;

library LibChainlinkPriceFeed {
  using LibPowMath for uint256;

  /**
   * @dev This is used to prevent overflow when scaling the price.
   * Reference: https://github.com/pancakeswap/pancake-smart-contracts/blob/cb079908a30328e46d42fe8cc77b9f7d38a15c2f/projects/farms-pools/contracts/SmartChef.sol#L94
   */
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
  error ComputedPriceTooLarge(uint256 price, int8 expo);
  /// @dev Thrown when the computed price is too small.
  error ComputedPriceTooSmall(uint256 price, int8 expo);

  /// @dev Emitted when the price feed is updated.
  event ChainlinkPriceFeedUpdated(
    AggregatorV2V3Interface indexed aggregator, uint8 tokenInDecimal, uint8 tokenOutDecimal, string description
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
    if (tokenInDecimal > _DECIMAL_LIMIT) revert LargeDecimal(tokenInDecimal);
    if (tokenOutDecimal > _DECIMAL_LIMIT) revert LargeDecimal(tokenOutDecimal);

    $._aggregator = AggregatorV2V3Interface(aggregator);
    $._tokenInDecimal = tokenInDecimal;
    $._tokenOutDecimal = tokenOutDecimal;
    $._maxAcceptableAge = maxAcceptableAge;

    emit ChainlinkPriceFeedUpdated(
      AggregatorV2V3Interface(aggregator),
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
    (uint256 price, uint8 priceDecimal) = quotePrice(priceFeed);

    // Scale the price to the same decimal as tokenOut
    uint256 scaledPrice = scalePrice(price, priceDecimal, priceFeed._tokenOutDecimal);

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
    (uint256 price, uint8 priceDecimal) = quotePrice(priceFeed);

    // Scale the price to the same decimal as tokenIn
    // The price is in tokenOut, so we need to inverseAndScalePrice it to get the tokenIn price
    uint256 inversedPrice = inverseAndScalePrice(price, priceDecimal, priceFeed._tokenInDecimal);

    tokenInAmount = Math.mulDiv(inversedPrice, tokenOutAmount, 10 ** priceFeed._tokenOutDecimal);
  }

  /**
   * @dev Get the price from the Chainlink price feed.
   * @param priceFeed The Chainlink price feed.
   * @return price The price in the given decimal.
   */
  function quotePrice(ChainlinkPriceFeed memory priceFeed) internal view returns (uint256 price, uint8 priceDecimal) {
    (, int256 answer,, uint256 updatedAt,) = priceFeed._aggregator.latestRoundData();
    if (updatedAt < block.timestamp - priceFeed._maxAcceptableAge) {
      revert PriceTooOld(updatedAt, block.timestamp - priceFeed._maxAcceptableAge);
    }
    if (answer <= 0) revert PanicNegativeQuotePrice(answer);

    priceDecimal = priceFeed._aggregator.decimals();
    if (priceDecimal > _DECIMAL_LIMIT) revert LargeDecimal(priceDecimal);

    return (uint256(answer), priceDecimal);
  }

  /**
   * @dev Scale the price to the given decimal.
   * @param price The price in the given decimal.
   * @param priceDecimal The decimal of the price.
   * @param desiredDecimal The decimal to scale the price to.
   * @return scaledPrice The scaled price in the given decimal.
   */
  function scalePrice(uint256 price, uint8 priceDecimal, uint8 desiredDecimal)
    internal
    pure
    returns (uint256 scaledPrice)
  {
    uint256 log10Price = Math.log10(price);
    if (desiredDecimal > priceDecimal && log10Price + (desiredDecimal - priceDecimal) > _MAX_DECIMAL) {
      revert ComputedPriceTooLarge(price, -(int8(desiredDecimal) - int8(priceDecimal)));
    }
    if (desiredDecimal < priceDecimal && log10Price < priceDecimal - desiredDecimal) {
      revert ComputedPriceTooSmall(price, -(int8(priceDecimal) - int8(desiredDecimal)));
    }

    return price.exp10(int8(desiredDecimal) - int8(priceDecimal));
  }

  /**
   * @dev Computes the inverse price of an asset pair (B/A) from (A/B) and scales it to the desired decimal precision.
   *
   * Given the price of (A/B), denoted as `x`, with decimal precision `d`, and the desired decimal `d'`,
   * the inverse price (B/A), denoted as `y`, is computed as:
   *
   *     y = (1 / x) * 10^d * 10^d'
   *       = (10^d / x) * 10^d'
   *       = 10^(d + d') / x
   *
   * @param price The price of (A/B) with `priceDecimal` precision.
   * @param priceDecimal The number of decimal places in `price`.
   * @param desiredDecimal The target number of decimal places for the inverse price.
   * @return inversedPrice The computed price of (B/A) scaled to `desiredDecimal`.
   */
  function inverseAndScalePrice(uint256 price, uint8 priceDecimal, uint8 desiredDecimal)
    internal
    pure
    returns (uint256 inversedPrice)
  {
    if (Math.log10(price) > priceDecimal + desiredDecimal) {
      revert ComputedPriceTooSmall(price, -(int8(desiredDecimal) - int8(priceDecimal)));
    }

    return 10 ** (desiredDecimal + priceDecimal) / price;
  }
}
