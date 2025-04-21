// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Test } from "../../dependencies/forge-std-1.8.2/src/Test.sol";
import { TokenFactory } from "src/factory/TokenFactory.sol";

contract TokenFactoryTest is Test {
  function test_DeployAXS() public {
    address axs = TokenFactory.createAXS();
    _assertTokenConfig(axs, "Axie Infinity Shard", "AXS", 18);
  }

  function test_DeploySLP(uint256 dailyLimit) public {
    address slp = TokenFactory.createSLP(dailyLimit);
    _assertTokenConfig(slp, "Smooth Love Potion", "SLP", 0);
  }

  function test_DeployUSDC() public {
    address usdc = TokenFactory.createUSDC();
    _assertTokenConfig(usdc, "USD Coin", "USDC", 6);
  }

  function test_DeployWETH() public {
    address weth = TokenFactory.createWETH();
    _assertTokenConfig(weth, "Ronin Wrapped Ether", "WETH", 18);
  }

  function _assertTokenConfig(address token, string memory name, string memory symbol, uint256 decimals) internal {
    bool success;
    bytes memory data;

    (success, data) = token.call(abi.encodeWithSignature("name()"));
    assert(success);
    assertEq(abi.decode(data, (string)), name, "Invalid name");

    (success, data) = token.call(abi.encodeWithSignature("symbol()"));
    assert(success);
    assertEq(abi.decode(data, (string)), symbol, "Invalid symbol");

    (success, data) = token.call(abi.encodeWithSignature("decimals()"));
    assert(success);
    assertEq(abi.decode(data, (uint256)), decimals, "Invalid decimals");
  }
}
