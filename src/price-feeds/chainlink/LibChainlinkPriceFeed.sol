// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV2V3Interface } from
  "../../../dependencies/chainlink-2.21.0/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import { Math } from "../../../dependencies/openzeppelin-4.9.6/contracts/utils/math/Math.sol";
import { LibPowMath } from "../../math/LibPowMath.sol";

struct ChainlinkPriceFeed {
  AggregatorV2V3Interface aggregator;
  int32 pairDecimal;
  int32 tokenInDecimal;
  int32 tokenOutDecimal;
}

using LibChainlinkPriceFeed for ChainlinkPriceFeed global;

library LibChainlinkPriceFeed {
  error QuotingPriceFailed();
  error ExponentTooLarge(int32 expo);
  error PositiveExponent(int32 expo);

  event ChainlinkPriceFeedUpdated(
    AggregatorV2V3Interface indexed aggregator, int32 tokenInDecimal, int32 tokenOutDecimal, string description
  );

  function set(ChainlinkPriceFeed storage $priceFeed, address aggregator, int32 tokenInDecimal, int32 tokenOutDecimal)
    internal
  {
    $priceFeed.aggregator = AggregatorV2V3Interface(aggregator);
    $priceFeed.tokenInDecimal = tokenInDecimal;
    $priceFeed.tokenOutDecimal = tokenOutDecimal;
    $priceFeed.pairDecimal = int32(uint32(AggregatorV2V3Interface(aggregator).decimals()));

    emit ChainlinkPriceFeedUpdated(
      AggregatorV2V3Interface(aggregator),
      tokenInDecimal,
      tokenOutDecimal,
      AggregatorV2V3Interface(aggregator).description()
    );
  }

  function convertTokenIn2TokenOut(ChainlinkPriceFeed memory priceFeed, uint256 tokenInWei)
    internal
    view
    returns (uint256 tokenOutWei)
  {
    uint256 price = quotePrice(priceFeed);

    // Scale the price to the same decimal as tokenOut
    uint256 scaledPrice = scalePrice(price, priceFeed.pairDecimal, priceFeed.tokenOutDecimal);

    tokenOutWei = Math.mulDiv(scaledPrice, tokenInWei, LibPowMath.exp10(1, int32(uint32(priceFeed.tokenInDecimal))));
  }

  function convertTokenOut2TokenIn(ChainlinkPriceFeed memory priceFeed, uint256 tokenOutWei)
    internal
    view
    returns (uint256 tokenInWei)
  {
    uint256 price = quotePrice(priceFeed);

    // Scale the price to the same decimal as tokenIn
    // The price is in tokenOut, so we need to inverse it to get the tokenIn price
    uint256 inversedPrice = inverse(int256(price), -priceFeed.pairDecimal, -priceFeed.tokenInDecimal);

    tokenInWei = Math.mulDiv(inversedPrice, tokenOutWei, LibPowMath.exp10(1, priceFeed.tokenOutDecimal));
  }

  function quotePrice(ChainlinkPriceFeed memory priceFeed) internal view returns (uint256 price) {
    try priceFeed.aggregator.latestAnswer() returns (int256 answer) {
      price = uint256(answer);
    } catch {
      try priceFeed.aggregator.latestRoundData() returns (uint80, int256 answer, uint256, uint256, uint80) {
        price = uint256(answer);
      } catch {
        revert QuotingPriceFailed();
      }
    }
  }

  function scalePrice(uint256 price, int32 pairDecimal, int32 scaledDecimal) internal pure returns (uint256) {
    return LibPowMath.exp10(price, scaledDecimal - pairDecimal);
  }

  function inverse(int256 price, int32 priceExpo, int32 expo) internal pure returns (uint256) {
    if (priceExpo > 0) revert PositiveExponent(expo);

    uint256 exp10p1 = LibPowMath.exp10(1, -priceExpo);
    if (exp10p1 > uint256(type(int256).max)) revert ExponentTooLarge(priceExpo);

    uint256 exp10p2 = LibPowMath.exp10(1, -expo);
    if (exp10p2 > uint256(type(int256).max)) revert ExponentTooLarge(expo);

    int256 inversedPrice = (int256(exp10p1) * int256(exp10p2)) / price;

    return uint256(inversedPrice);
  }
}
