// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Test } from "forge-std/Test.sol";
import { Gas, LibNativeTransfer } from "contract-libs/transfers/LibNativeTransfer.sol";

contract LibNativeTransferTest is Test {
  function testFork_RevertWhen_TransferNativeToContractWithoutFallback_safeTransfer(
    address any,
    uint256 amount,
    uint8 v
  ) external {
    vm.deal(any, amount);
    vm.expectRevert();
    vm.prank(any);
    LibNativeTransfer.safeTransfer(address(this), amount, _toGas(v));
  }

  function testConcrete_TransferNative(uint8 v) external {
    LibNativeTransfer.safeTransfer(address(0xBEEF), 1e18, _toGas(v));
    assertEq(address(0xBEEF).balance, 1e18);
  }

  function testFork_TransferNativeToRecipient(address recipient, uint256 amount, uint8 v) external {
    // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
    if (recipient.code.length > 0 || uint256(uint160(recipient)) <= 18 || recipient == msg.sender) return;

    amount = bound(amount, 0, address(this).balance);
    LibNativeTransfer.safeTransfer(recipient, amount, _toGas(v));

    assertEq(recipient.balance, amount);
  }

  function _toGas(uint8 v) internal view returns (Gas gas) {
    v = uint8(bound(v, 0, 3));
    if (v == uint8(Gas.Strictly)) gas = Gas.Strictly;
    if (v == uint8(Gas.NoGriefing)) gas = Gas.NoGriefing;
    if (v == uint8(Gas.ForwardAll)) gas = Gas.ForwardAll;
    if (v == uint8(Gas.NoStorageWrite)) gas = Gas.NoStorageWrite;
  }
}
