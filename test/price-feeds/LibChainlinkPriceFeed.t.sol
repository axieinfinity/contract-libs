// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Test } from "../../dependencies/forge-std-1.8.2/src/Test.sol";
import { VmSafe } from "../../dependencies/forge-std-1.8.2/src/Vm.sol";
import { console } from "../../dependencies/forge-std-1.8.2/src/console.sol";
import { ChainlinkPriceFeed, LibChainlinkPriceFeed } from "../../src/price-feeds/chainlink/LibChainlinkPriceFeed.sol";
import { PythPriceFeed } from "../../src/price-feeds/pyth/LibPythPriceFeed.sol";
import { AggregatorV2V3Interface } from
  "../../dependencies/chainlink-2.21.0/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import { LibPowMath } from "../../src/math/LibPowMath.sol";
import { Math } from "../../dependencies/openzeppelin-4.9.6/contracts/utils/math/Math.sol";
import { SafeMath } from "../../dependencies/openzeppelin-4.9.6/contracts/utils/math/SafeMath.sol";
import { SafeCast } from "../../dependencies/openzeppelin-4.9.6/contracts/utils/math/SafeCast.sol";

contract MockRONPriceFeed {
  function latestTimestamp() public pure returns (uint256) {
    return 1742296233;
  }

  function latestAnswer() public pure returns (int256) {
    return 77694561;
  }

  function latestRoundData()
    public
    pure
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    return (18446744073709555266, 77694561, 1742278624, 1742278642, 18446744073709555266);
  }
}

contract PythPriceRONQuoterSample {
  PythPriceFeed public ronPriceFeed;

  function set(address aggregator, uint8 tokenInDecimal, uint8 tokenOutDecimal, bytes32 priceId) external {
    ronPriceFeed.set(aggregator, tokenInDecimal, tokenOutDecimal, priceId, 1 days);
  }

  function convertTokenIn2TokenOut(uint256 tokenInWei) external view returns (uint256 tokenOutWei) {
    tokenOutWei = ronPriceFeed.convertTokenIn2TokenOut(tokenInWei);
  }

  function convertTokenOut2TokenIn(uint256 tokenOutWei) external view returns (uint256 tokenInWei) {
    tokenInWei = ronPriceFeed.convertTokenOut2TokenIn(tokenOutWei);
  }
}

contract ChainlinkPriceRONQuoterSample {
  ChainlinkPriceFeed public ronPriceFeed;

  function set(address aggregator, int32 tokenInDecimal, int32 tokenOutDecimal) external {
    ronPriceFeed.set(aggregator, tokenInDecimal, tokenOutDecimal, 1 days);
  }

  function convertTokenIn2TokenOut(uint256 tokenInWei) external view returns (uint256 tokenOutWei) {
    tokenOutWei = ronPriceFeed.convertTokenIn2TokenOut(tokenInWei);
  }

  function convertTokenOut2TokenIn(uint256 tokenOutWei) external view returns (uint256 tokenInWei) {
    tokenInWei = ronPriceFeed.convertTokenOut2TokenIn(tokenOutWei);
  }
}

contract LibChainlinkPriceFeedTest is Test {
  using LibPowMath for *;
  using Math for *;
  using SafeCast for *;
  using SafeMath for *;

  uint8 internal _maxDecimal;
  uint256 internal _mainnetForkId;
  uint256 internal _testnetForkId;

  mapping(uint256 chainId => bytes32 pythId) internal _pythPriceId;
  mapping(uint256 chainId => address pyth) internal _pythAggregator;
  mapping(uint256 chainid => address cl) internal _chainlinkAggregator;

  modifier safeDecimal(uint8 decimal) {
    vm.assume(decimal < _maxDecimal);
    _;
  }

  modifier safePrecision(uint256 price, uint8 decimal) {
    vm.assume(Math.log10(price) + decimal < _maxDecimal);
    (bool ok,) = SafeMath.tryMul(price, 10 ** decimal);
    vm.assume(ok);
    _;
  }

  function setUp() public {
    _maxDecimal = type(uint256).max.log10().toUint8();
    vm.warp(1742296320);

    console.log("Max decimal: %d", _maxDecimal);

    _mainnetForkId = vm.createFork("ronin-mainnet", 43480534);
    _testnetForkId = vm.createFork("ronin-testnet", 36183564);

    _pythPriceId[2021] = 0x4cb9d530b042004b042e165ee0904b12fe534d40dac5fe1c71dfcdb522e6e3c2;
    _pythPriceId[2020] = 0x97cfe19da9153ef7d647b011c5e355142280ddb16004378573e6494e499879f3;

    _pythAggregator[2021] = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    _pythAggregator[2020] = 0x2880aB155794e7179c9eE2e38200202908C17B43;

    _chainlinkAggregator[2020] = 0x0B6074F21488B95945989E513EFEA070096d931D;
    _chainlinkAggregator[2021] = 0xBaA0AfA2f390349e0074bE787509a098e3044fc8;
  }

  function testFork_Testnet_ConvertUSD2RON_Pyth_Vs_Chainlink() public {
    vm.selectFork(_testnetForkId);

    PythPriceRONQuoterSample pythQuoter = new PythPriceRONQuoterSample();
    pythQuoter.set(_pythAggregator[2021], 18, 6, _pythPriceId[2021]);

    ChainlinkPriceRONQuoterSample chainlinkQuoter = new ChainlinkPriceRONQuoterSample();
    chainlinkQuoter.set(_chainlinkAggregator[2021], 18, 6);

    uint256 usdAmount = 150e6;
    uint256 pythPrice = pythQuoter.convertTokenOut2TokenIn(usdAmount);
    uint256 chainlinkPrice = chainlinkQuoter.convertTokenOut2TokenIn(usdAmount);

    assertApproxEqRel(pythPrice, chainlinkPrice, 2e16, "Incorrect price conversion");
  }

  function testFork_Mainnet_ConvertUSD2RON_Pyth_Vs_Chainlink() public {
    vm.selectFork(_mainnetForkId);

    PythPriceRONQuoterSample pythQuoter = new PythPriceRONQuoterSample();
    pythQuoter.set(_pythAggregator[2020], 18, 6, _pythPriceId[2020]);

    ChainlinkPriceRONQuoterSample chainlinkQuoter = new ChainlinkPriceRONQuoterSample();
    chainlinkQuoter.set(_chainlinkAggregator[2020], 18, 6);

    uint256 usdAmount = 100e6;
    uint256 pythPrice = pythQuoter.convertTokenOut2TokenIn(usdAmount);
    uint256 chainlinkPrice = chainlinkQuoter.convertTokenOut2TokenIn(usdAmount);

    assertApproxEqRel(pythPrice, chainlinkPrice, 1e16, "Incorrect price conversion");
  }

  function testFork_Testnet_ConvertRON2USD_Pyth_Vs_Chainlink() public {
    vm.selectFork(_testnetForkId);

    PythPriceRONQuoterSample pythQuoter = new PythPriceRONQuoterSample();
    pythQuoter.set(_pythAggregator[2021], 18, 6, _pythPriceId[2021]);

    ChainlinkPriceRONQuoterSample chainlinkQuoter = new ChainlinkPriceRONQuoterSample();
    chainlinkQuoter.set(_chainlinkAggregator[2021], 18, 6);

    uint256 ronAmount = 50e18;
    uint256 pythPrice = pythQuoter.convertTokenIn2TokenOut(ronAmount);
    uint256 chainlinkPrice = chainlinkQuoter.convertTokenIn2TokenOut(ronAmount);

    assertApproxEqRel(pythPrice, chainlinkPrice, 2e16, "Incorrect price conversion");
  }

  function testFork_Mainnet_ConvertRON2USD_Pyth_Vs_Chainlink() public {
    vm.selectFork(_mainnetForkId);

    PythPriceRONQuoterSample pythQuoter = new PythPriceRONQuoterSample();
    pythQuoter.set(_pythAggregator[2020], 18, 6, _pythPriceId[2020]);

    ChainlinkPriceRONQuoterSample chainlinkQuoter = new ChainlinkPriceRONQuoterSample();
    chainlinkQuoter.set(_chainlinkAggregator[2020], 18, 6);

    uint256 ronAmount = 250e18;
    uint256 pythPrice = pythQuoter.convertTokenIn2TokenOut(ronAmount);
    uint256 chainlinkPrice = chainlinkQuoter.convertTokenIn2TokenOut(ronAmount);

    assertApproxEqRel(pythPrice, chainlinkPrice, 1e16, "Incorrect price conversion");
  }

  function testConcrete_ConvertRON2USD() public {
    ChainlinkPriceFeed memory converter = ChainlinkPriceFeed({
      aggregator: AggregatorV2V3Interface(address(new MockRONPriceFeed())),
      pairDecimal: 8,
      tokenInDecimal: 18,
      tokenOutDecimal: 18,
      maxAcceptableAge: 1 days
    });

    uint256 ronAmount = 50e18;
    uint256 ronPrice = LibChainlinkPriceFeed.convertTokenIn2TokenOut(converter, ronAmount);

    assertEq(ronPrice, ronAmount * 77694561 / 1e8, "Incorrect price conversion");
  }

  function testConcrete_ConvertUSD2RON() public {
    ChainlinkPriceFeed memory converter = ChainlinkPriceFeed({
      aggregator: AggregatorV2V3Interface(address(new MockRONPriceFeed())),
      pairDecimal: 8,
      tokenInDecimal: 18,
      tokenOutDecimal: 18,
      maxAcceptableAge: 1 days
    });

    uint256 usdAmount = 100e18;
    uint256 ronPrice = LibChainlinkPriceFeed.convertTokenOut2TokenIn(converter, usdAmount);

    assertApproxEqAbs(ronPrice, 128709138339812487002, 100, "Incorrect price conversion");
    assertApproxEqAbs(ronPrice, usdAmount * 1e8 / 77694561, 100, "Incorrect price conversion");
  }

  function testFuzz_Inverse_Calculate_Correctly(uint256 price, uint8 priceDecimal, uint8 decimal)
    public
    safeDecimal(priceDecimal)
    safeDecimal(decimal)
    safePrecision(uint256(price), decimal)
    safePrecision(uint256(price), priceDecimal)
  {
    vm.assume(priceDecimal < 19);
    vm.assume(decimal < 19);
    vm.assume(price > 0);

    uint256 got = LibChainlinkPriceFeed.inverse(int256(price), -int32(uint32(priceDecimal)), -int32(uint32(decimal)));

    // Python script to calculate the expected value
    // print('res:', int(1e{priceDecimal}/{price} * 10**{decimal}))
    string[] memory cmd = new string[](3);
    cmd[0] = "python";
    cmd[1] = "-c";
    cmd[2] = string.concat(
      "print('res:',",
      "int(1e",
      vm.toString(priceDecimal),
      "/",
      vm.toString(price),
      " * 10**",
      vm.toString(decimal),
      "))"
    );

    VmSafe.FfiResult memory ret = vm.tryFfi(cmd);
    require(ret.exitCode == 0, string.concat("Python script failed. Reason: ", string(ret.stderr)));

    string memory result = string(ret.stdout);
    uint256 expected = vm.parseUint(vm.replace(result, "res: ", ""));

    // allow max delta precision of of 5% 0-100% = [0, 1e18]
    assertApproxEqRel(got, expected, 5e16, "Incorrect inverse price");
  }

  function testConcrete_Inverse() public pure {
    // Case 0: priceExpo == expo
    int256 price = 1e8;
    int32 expo = -8;
    uint256 weiPrice = LibChainlinkPriceFeed.inverse(price, expo, expo);
    assertEq(weiPrice, 100000000, "Incorrect inverse price");

    // Case 1: priceExpo > expo
    // WBTC/USD price
    price = 334172000;
    expo = -8;
    uint256 weiPrice2 = LibChainlinkPriceFeed.inverse(price, expo, -18);
    assertEq(weiPrice2, 299247094310714242, "Incorrect inverse price");
    assertApproxEqAbs(
      LibChainlinkPriceFeed.inverse(int256(weiPrice2), -18, expo), uint256(price), 100, "Incorrect inverse price"
    );

    // Case 2: priceExpo < expo
    // USDC/USD price
    price = 99992523;
    expo = -8;
    uint256 weiPrice3 = LibChainlinkPriceFeed.inverse(price, expo, -6);
    assertEq(weiPrice3, 1000074, "Incorrect inverse price");
    assertApproxEqAbs(
      LibChainlinkPriceFeed.inverse(int256(weiPrice3), -6, expo), uint256(price), 100, "Incorrect inverse price"
    );
  }

  function testConcrete_ScalePrice_Calculate_Correctly() public pure {
    // WBTC/USD price
    uint256 price = 334172000;
    uint8 priceDecimal = 8;

    // Case 1: priceDecimal == decimal
    assertEq(price, LibChainlinkPriceFeed.scalePrice(price, int32(uint32(priceDecimal)), 8), "Incorrect price scaling");

    // Case 2: priceDecimal < decimal
    uint256 weiPrice = LibChainlinkPriceFeed.scalePrice(price, int32(uint32(priceDecimal)), 18);
    assertEq(weiPrice, 3341720000000000000, "Incorrect price scaling");

    // Case 3: priceDecimal > decimal
    uint256 weiPrice2 = LibChainlinkPriceFeed.scalePrice(price, int32(uint32(priceDecimal)), 6);
    assertEq(weiPrice2, 3341720, "Incorrect price scaling");

    // Case 4: reverse scaling
    uint256 oriPrice = LibChainlinkPriceFeed.scalePrice(weiPrice, 18, int32(uint32(priceDecimal)));
    assertEq(oriPrice, price, "Incorrect price scaling");

    // RON/USD price
    price = 77694561;
    priceDecimal = 8;

    // Case 1: priceDecimal == decimal
    assertEq(price, LibChainlinkPriceFeed.scalePrice(price, int32(uint32(priceDecimal)), 8), "Incorrect price scaling");

    // Case 2: priceDecimal < decimal
    weiPrice = LibChainlinkPriceFeed.scalePrice(price, int32(uint32(priceDecimal)), 18);
    assertEq(weiPrice, 776945610000000000, "Incorrect price scaling");

    // Case 3: priceDecimal > decimal
    weiPrice2 = LibChainlinkPriceFeed.scalePrice(price, int32(uint32(priceDecimal)), 6);
    assertEq(weiPrice2, 776945, "Incorrect price scaling");

    // Case 4: reverse scaling
    oriPrice = LibChainlinkPriceFeed.scalePrice(weiPrice, 18, int32(uint32(priceDecimal)));
  }

  function testFuzz_ScalePrice_Calculate_Correctly(uint256 price, uint8 priceDecimal, uint8 decimal)
    public
    view
    safeDecimal(priceDecimal)
    safeDecimal(decimal)
    safePrecision(uint256(price), decimal)
    safePrecision(uint256(price), priceDecimal)
  {
    uint256 got = LibChainlinkPriceFeed.scalePrice(price, int32(uint32(priceDecimal)), int32(uint32(decimal)));
    console.log("Got", got);
    uint256 expected = uint256(scalePrice(price, priceDecimal, decimal));
    console.log("Expected", expected);

    assertEq(got, expected, "Incorrect price scaling");
  }

  function scalePrice(uint256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns (uint256) {
    if (_priceDecimals < _decimals) {
      return _price * uint256(10 ** uint256(_decimals - _priceDecimals));
    } else if (_priceDecimals > _decimals) {
      return _price / uint256(10 ** uint256(_priceDecimals - _decimals));
    }
    return _price;
  }

  function latestRoundData()
    public
    pure
    returns (uint80 roundId, uint256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    return (18446744073709553440, 8311679190297, 1742261649, 1742261667, 18446744073709553440);
  }
}
