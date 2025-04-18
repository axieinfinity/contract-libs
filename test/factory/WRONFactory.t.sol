// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Test } from "../../dependencies/forge-std-1.8.2/src/Test.sol";
import { WRONFactory } from "src/factory/WRONFactory.sol";
import { IWRON } from "src/interfaces/IWRON.sol";
import { IWRONHelper } from "src/interfaces/IWRONHelper.sol";

contract WRONFactoryTest is Test {
  IWRON wron;
  IWRONHelper wronHelper;

  function setUp() public {
    wron = WRONFactory.createWRON();
    assert(address(wron).code.length > 0);
    wronHelper = WRONFactory.createWRONHelper(address(wron));
  }

  function test_WRONConfigs() external view {
    assertEq(wron.name(), "Wrapped Ronin");
    assertEq(wron.symbol(), "WRON");
    assertEq(wron.decimals(), 18);
  }

  function test_WRON_Deposit_Withdraw(uint256 fund) external {
    vm.assume(fund > 0);
    address user = makeAddr("user");
    vm.deal(user, fund);

    vm.prank(user);
    wron.deposit{ value: fund }();

    assertEq(wron.balanceOf(user), fund);

    vm.prank(user);
    wron.withdraw(fund);

    assertEq(wron.balanceOf(user), 0);
    assertEq(user.balance, fund);
  }

  function test_WRONHelperConfigs() external view {
    assertEq(address(wronHelper.WRON()), address(wron));
  }

  function test_WRONHelper_And_Withdraw(uint256 fund) external {
    vm.assume(fund > 0);
    address user = makeAddr("user");
    address payable recipient = payable(makeAddr("recipient"));

    vm.deal(user, fund);
    vm.prank(user);
    wron.deposit{ value: fund }();

    vm.startPrank(user);
    wron.approve(address(wronHelper), fund);
    wronHelper.withdrawTo(recipient, fund);
    vm.stopPrank();

    assertEq(wron.balanceOf(user), 0);
    assertEq(recipient.balance, fund);
  }
}
