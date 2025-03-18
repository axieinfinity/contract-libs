// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PythStructs } from "../../../dependencies/pyth-2.2.0/PythStructs.sol";
import { Math } from "../../../dependencies/openzeppelin-4.9.6/contracts/utils/math/Math.sol";
import { LibPowMath } from "../../math/LibPowMath.sol";
import { IPyth } from "../../../dependencies/pyth-2.2.0/IPyth.sol";

struct PythPriceFeed {
  uint8 tokenInDecimal;
  uint8 tokenOutDecimal;
  IPyth pyth;
  bytes32 priceId;
  uint256 maxAcceptableAge;
}

using LibPythPriceFeed for PythPriceFeed global;

library LibPythPriceFeed {
  using LibPythPriceFeed for PythStructs.Price;

  error ErrExponentTooLarge(int32 expo);
  error ErrComputedPriceTooLarge(int32 expo1, int32 expo2, int64 price1);
  error ErrPositiveExponent(int32 expo);

  /**
   * @dev Emitted when the price feed is updated.
   * @param pyth The Pyth contract.
   * @param priceId The price id.
   * @param tokenInDecimal The decimal of the token in.
   * @param tokenOutDecimal The decimal of the token out.
   * @param maxAcceptableAge The max acceptable age for the price.
   */
  event PythPriceFeedUpdated(
    IPyth indexed pyth, bytes32 indexed priceId, uint8 tokenInDecimal, uint8 tokenOutDecimal, uint256 maxAcceptableAge
  );

  /**
   * @dev Sets the price feed for a token.
   * @param priceFeed The price feed.
   * @param pyth The Pyth contract.
   * @param tokenInDecimal The decimal of token in.
   * @param tokenOutDecimal The decimal of token out.
   * @param priceId The price id.
   * @param maxAcceptableAge The max acceptable age for the price.
   */
  function set(
    PythPriceFeed storage priceFeed,
    address pyth,
    uint8 tokenInDecimal,
    uint8 tokenOutDecimal,
    bytes32 priceId,
    uint256 maxAcceptableAge
  ) internal {
    priceFeed.pyth = IPyth(pyth);
    priceFeed.priceId = priceId;
    priceFeed.tokenInDecimal = tokenInDecimal;
    priceFeed.tokenOutDecimal = tokenOutDecimal;
    priceFeed.maxAcceptableAge = maxAcceptableAge;

    emit PythPriceFeedUpdated(IPyth(pyth), priceId, tokenInDecimal, tokenOutDecimal, maxAcceptableAge);
  }

  /**
   * @dev Converts the token in into token out.
   */
  function convertTokenIn2TokenOut(PythPriceFeed memory priceFeed, uint256 tokenInWei)
    internal
    view
    returns (uint256 tokenOutWei)
  {
    return priceFeed.pyth.getPriceNoOlderThan(priceFeed.priceId, priceFeed.maxAcceptableAge).mul({
      inpWei: tokenInWei,
      inpDecimals: int32(uint32(priceFeed.tokenInDecimal)),
      outDecimals: int32(uint32(priceFeed.tokenOutDecimal))
    });
  }

  /**
   * @dev Converts the token out into token in.
   */
  function convertTokenOut2TokenIn(PythPriceFeed memory priceFeed, uint256 tokenOutWei)
    internal
    view
    returns (uint256 tokenInWei)
  {
    return priceFeed.pyth.getPriceNoOlderThan(priceFeed.priceId, priceFeed.maxAcceptableAge).inverse({
      expo: -int32(uint32(priceFeed.tokenInDecimal))
    }).mul({
      inpWei: tokenOutWei,
      inpDecimals: int32(uint32(priceFeed.tokenOutDecimal)),
      outDecimals: int32(uint32(priceFeed.tokenInDecimal))
    });
  }

  /**
   * @dev Multiples and converts the price into token wei with decimals `outDecimals`.
   */
  function mul(PythStructs.Price memory self, uint256 inpWei, int32 inpDecimals, int32 outDecimals)
    internal
    pure
    returns (uint256 outWei)
  {
    return Math.mulDiv(
      inpWei, LibPowMath.exp10(uint256(int256(self.price)), outDecimals + self.expo), LibPowMath.exp10(1, inpDecimals)
    );
  }

  /**
   * @dev Inverses token price of tokenA/tokenB to tokenB/tokenA.
   */
  function inverse(PythStructs.Price memory self, int32 expo) internal pure returns (PythStructs.Price memory outPrice) {
    if (self.expo > 0) revert ErrPositiveExponent(expo);

    uint256 exp10p1 = LibPowMath.exp10(1, -self.expo);
    if (exp10p1 > uint256(type(int256).max)) revert ErrExponentTooLarge(self.expo);

    uint256 exp10p2 = LibPowMath.exp10(1, -expo);
    if (exp10p2 > uint256(type(int256).max)) revert ErrExponentTooLarge(expo);

    int256 price = (int256(exp10p1) * int256(exp10p2)) / self.price;
    if (price > type(int64).max) revert ErrComputedPriceTooLarge(self.expo, expo, self.price);

    return PythStructs.Price({ price: int64(price), conf: self.conf, expo: expo, publishTime: self.publishTime });
  }
}
