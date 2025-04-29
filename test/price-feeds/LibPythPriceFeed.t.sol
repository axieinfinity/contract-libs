// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Test } from "../../dependencies/forge-std-1.8.2/src/Test.sol";
import { PythStructs } from "../../src/interfaces/PythStructs.sol";
import { LibPowMath } from "../../src/math/LibPowMath.sol";
import "../../src/price-feeds/pyth/LibPythPriceFeed.sol";
import "../../dependencies/openzeppelin-4.9.6/contracts/utils/math/Math.sol";
import "../../dependencies/openzeppelin-4.9.6/contracts/utils/math/SignedMath.sol";
import "../../dependencies/openzeppelin-4.9.6/contracts/utils/math/SafeCast.sol";
import "../../dependencies/openzeppelin-4.9.6/contracts/utils/math/SafeMath.sol";

contract LibPythPriceFeedTest is Test {
  using LibPythPriceFeed for PythStructs.Price;
  using Math for *;
  using SignedMath for *;
  using SafeCast for *;
  using SafeMath for *;

  uint64 public constant MAX_PERCENTAGE = 100_00;
  uint64 public constant EPS = 100;

  bytes32 public constant RONUSD_ID = keccak256("RONUSD_ID");
  bytes32 public constant USDRON_ID = keccak256("USDRON_ID");

  uint8 internal _maxDecimals;
  bytes32[] internal _pythIds;

  modifier safeDecimals(uint8 decimals) {
    vm.assume(decimals < 19);
    _;
  }

  modifier safeWei(uint256 inpWei) {
    vm.assume(Math.log10(inpWei) + Math.log10(getPrice(RONUSD_ID).price.toUint256() * 1e18) < _maxDecimals);
    _;
  }

  modifier safeTokenAmount(uint256 amount, uint8 decimals) {
    (bool ok,) = amount.tryMul(10 ** decimals);
    vm.assume(ok);
    _;
  }

  function setUp() public {
    _maxDecimals = Math.log10(type(uint256).max).toUint8();
    _pythIds.push(RONUSD_ID);
    _pythIds.push(USDRON_ID);
  }

  function testFuzz_Convert_RONWeiToUSDWei(uint256 inpWei, uint8 outDecimals)
    public
    view
    safeWei(inpWei)
    safeDecimals(outDecimals)
    returns (uint256 calc)
  {
    PythStructs.Price memory out = getPrice(RONUSD_ID);
    calc = out.inverse(-18).mul({ inpWei: inpWei, inpDecimals: 18, outDecimals: int32(uint32(outDecimals)) });
    uint256 expt =
      inpWei.mulDiv(LibPowMath.exp10(1, int32(uint32(outDecimals)) - out.expo) / out.price.toUint256(), 1e18);
    assertEq(calc, expt);
  }

  function testConcrete_Convert_RONWeiToUSDWei() public view {
    assertEq(testFuzz_Convert_RONWeiToUSDWei(1e18, 8), 206943385);
    assertEq(testFuzz_Convert_RONWeiToUSDWei(2e18, 9), 4138867702);
    assertEq(testFuzz_Convert_RONWeiToUSDWei(4e18, 10), 82777354060);
  }

  function testFuzz_Convert_USDWeiToRONWei(uint256 inpWei, uint8 usdDecimals)
    public
    view
    safeDecimals(usdDecimals)
    safeWei(inpWei)
    returns (uint256 calc)
  {
    uint256 inpMask = LibPowMath.exp10(1, int32(uint32(usdDecimals)));

    PythStructs.Price memory out = getPrice(RONUSD_ID);
    calc = out.mul({ inpWei: inpWei, inpDecimals: int32(uint32(usdDecimals)), outDecimals: 18 });
    uint256 expt = inpWei.mulDiv(LibPowMath.exp10(out.price.toUint256(), 18 + out.expo), inpMask);
    assertEq(calc, expt);
  }

  function testFuzz_Convert_USDAmountToRONWei(uint256 usd, uint8 usdDecimals)
    public
    view
    safeDecimals(usdDecimals)
    safeTokenAmount(usd, usdDecimals)
    returns (uint256 calc)
  {
    return testFuzz_Convert_USDWeiToRONWei(usd * 10 ** usdDecimals, usdDecimals);
  }

  function testFuzz_Convert_USDAmountToRONWei(uint8 decimals) public view safeDecimals(decimals) {
    assertEq(testFuzz_Convert_USDAmountToRONWei(1, decimals), 483223950000000000);
    assertEq(testFuzz_Convert_USDAmountToRONWei(2, decimals), 966447900000000000);
    assertEq(testFuzz_Convert_USDAmountToRONWei(4, decimals), 1932895800000000000);
    assertEq(testFuzz_Convert_USDAmountToRONWei(8, decimals), 3865791600000000000);
    assertEq(testFuzz_Convert_USDAmountToRONWei(16, decimals), 7731583200000000000);
    assertEq(testFuzz_Convert_USDAmountToRONWei(32, decimals), 15463166400000000000);
  }

  function testConcrete_Convert_USDWeiToRONWei() public view {
    assertEq(testFuzz_Convert_USDWeiToRONWei(100000000, 8), 483223950000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(200000000, 8), 966447900000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(400000000, 8), 1932895800000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(800000000, 8), 3865791600000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(1600000000, 8), 7731583200000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(3200000000, 8), 15463166400000000000);

    assertEq(testFuzz_Convert_USDWeiToRONWei(1000000000000000000, 18), 483223950000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(2000000000000000000, 18), 966447900000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(4000000000000000000, 18), 1932895800000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(8000000000000000000, 18), 3865791600000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(16000000000000000000, 18), 7731583200000000000);
    assertEq(testFuzz_Convert_USDWeiToRONWei(32000000000000000000, 18), 15463166400000000000);
  }

  function testFuzz_Inverse(uint8 idIdx, uint8 inverseTimes) public view {
    vm.assume(inverseTimes > 0);
    uint256 inpIdx = idIdx % _pythIds.length;
    uint256 outIdx = (uint256(idIdx) + inverseTimes) % _pythIds.length;

    PythStructs.Price memory pythOutput = getPrice(_pythIds[inpIdx]);
    for (uint256 i = 0; i < inverseTimes; i++) {
      pythOutput = pythOutput.inverse({ expo: -8 });
    }

    assertEq(pythOutput.price, getPrice(_pythIds[outIdx]).price);
  }

  function testConcrete_Inverse() public pure {
    assertEq(getPrice(RONUSD_ID).price, getPrice(USDRON_ID).inverse({ expo: -8 }).price);
    assertEq(getPrice(USDRON_ID).price, getPrice(RONUSD_ID).inverse({ expo: -8 }).price);
  }

  function getPrice(bytes32 id) public pure returns (PythStructs.Price memory) {
    if (id == RONUSD_ID) return PythStructs.Price({ price: 48322395, conf: 116535, expo: -8, publishTime: 0 });
    if (id == USDRON_ID) return PythStructs.Price({ price: 206943385, conf: 116535, expo: -8, publishTime: 0 });
    return PythStructs.Price({ price: 0, conf: 0, expo: 0, publishTime: 0 });
  }
}
