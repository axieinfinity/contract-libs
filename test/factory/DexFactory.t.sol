// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Test } from "../../dependencies/forge-std-1.8.2/src/Test.sol";
import { IKatanaRouter } from "src/interfaces/IKatanaRouter.sol";
import { IKatanaFactory } from "src/interfaces/IKatanaFactory.sol";
import { IKatanaPair } from "src/interfaces/IKatanaPair.sol";
import { IWRON } from "src/interfaces/IWRON.sol";
import { DexFactory } from "src/factory/DexFactory.sol";
import { WRONFactory } from "src/factory/WRONFactory.sol";
import { ERC20PresetMinterPauser } from
  "../../dependencies/openzeppelin-4.9.6/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract DexFactoryTest is Test {
  IKatanaPair pairImpl;
  IKatanaFactory factory;
  IKatanaRouter router;
  IWRON wron;

  ERC20PresetMinterPauser tokenA;
  ERC20PresetMinterPauser tokenB;

  address treasury = makeAddr("treasury");
  address provider = makeAddr("liquidity-provider");

  function setUp() public {
    wron = WRONFactory.createWRON();
    pairImpl = DexFactory.createPair();
    factory = DexFactory.createFactory(treasury, address(pairImpl));
    router = DexFactory.createRouter(address(factory), address(wron));

    tokenA = new ERC20PresetMinterPauser("TokenA", "TA");
    tokenB = new ERC20PresetMinterPauser("TokenB", "TB");

    tokenA.mint(provider, 10_000 ether);
    tokenB.mint(provider, 10_000 ether);
    vm.deal(provider, 10_000 ether);
  }

  function test_Dex_Fullflow() public {
    // create pair
    factory.createPair(address(tokenA), address(tokenB));
    factory.createPair(address(tokenA), address(wron));

    // add fund to pair
    vm.startPrank(provider);
    tokenA.approve(address(router), 10_000 ether);
    tokenB.approve(address(router), 10_000 ether);

    router.addLiquidity(address(tokenA), address(tokenB), 1000 ether, 2000 ether, 0, 0, provider, type(uint256).max);
    router.addLiquidityRON{ value: 4000 ether }(address(tokenA), 4000 ether, 0, 0, provider, type(uint256).max);
    vm.stopPrank();

    // swap
    address user = makeAddr("user");
    address[] memory path = new address[](3);
    path[0] = address(wron);
    path[1] = address(tokenA);
    path[2] = address(tokenB);

    vm.deal(user, 10 ether);
    vm.prank(user);
    router.swapExactRONForTokens{ value: 10 ether }(0, path, user, type(uint256).max);
  }
}
