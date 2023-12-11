// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Test } from "forge-std/Test.sol";
import { LibNativeTransfer } from "src/transfers/LibNativeTransfer.sol";

contract LibNativeTransferTest is Test {
  function testFork_RevertWhen_TransferNativeToContractWithoutFallback_safeTransfer(
    address any,
    uint256 amount,
    uint256 gas
  ) external {
    vm.deal(any, amount);
    vm.expectRevert();
    vm.prank(any);
    LibNativeTransfer.transfer(address(this), amount, gas);
  }

  function testConcrete_TransferNative(uint256 gas) external {
    LibNativeTransfer.transfer(address(0xBEEF), 1e18, gas);
    assertEq(address(0xBEEF).balance, 1e18);
  }

  function testFork_TransferNativeToRecipient(address recipient, uint256 amount, uint256 gas) external {
    // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
    if (recipient.code.length > 0 || uint256(uint160(recipient)) <= 18 || recipient == msg.sender) return;

    amount = bound(amount, 0, address(this).balance);
    LibNativeTransfer.transfer(recipient, amount, gas);

    assertEq(recipient.balance, amount);
  }
}
