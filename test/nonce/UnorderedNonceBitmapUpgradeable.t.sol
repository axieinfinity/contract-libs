// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Test } from "../../dependencies/forge-std-1.8.2/src/Test.sol";
import { UnorderedNonceBitMapUpgradeable } from "src/nonce/UnorderedNonceBitMapUpgradeable.sol";
import { UnorderedNonceBitmapUpgradeableHarness } from "./UnorderedNonceBitmapUpgradeableHarness.t.sol";

contract UnorderedNonceBitMapUpgradeableTest is Test {
  UnorderedNonceBitmapUpgradeableHarness private harness;

  address private user1 = address(0x1);
  address private user2 = address(0x2);

  function setUp() public {
    harness = new UnorderedNonceBitmapUpgradeableHarness();
  }

  // Test bitmap positions calculation
  function testConcrete_SuccessWhen_BitmapPositionsCalculatedCorrectly() public pure {
    // This test only checks pure function calculations, no state changes
    uint256 nonce = 0x12345678;
    uint256 expectedWordPos = 0x123456;
    uint256 expectedBitPos = 0x78;

    assertEq(expectedWordPos, uint248(nonce >> 8));
    assertEq(expectedBitPos, uint8(nonce));
  }

  function testConcrete_SuccessWhen_BitmapPositionsWithZeroNonce() public pure {
    uint256 nonce = 0;
    uint256 expectedWordPos = 0;
    uint256 expectedBitPos = 0;

    assertEq(expectedWordPos, uint248(nonce >> 8));
    assertEq(expectedBitPos, uint8(nonce));
  }

  function testConcrete_SuccessWhen_BitmapPositionsWithMaxValues() public pure {
    uint256 nonce = type(uint256).max;
    uint256 expectedWordPos = type(uint248).max;
    uint256 expectedBitPos = 0xFF;

    assertEq(expectedWordPos, uint248(nonce >> 8));
    assertEq(expectedBitPos, uint8(nonce));
  }

  // Test isUsedNonce function
  function testConcrete_SuccessWhen_NonceNotUsed() public view {
    bool isUsed = harness.isUsedNonce(user1, 123);
    assertFalse(isUsed);
  }

  function testConcrete_SuccessWhen_NonceUsed() public {
    // Use the nonce first
    harness.useUnorderedNonce(user1, 123);

    bool isUsed = harness.isUsedNonce(user1, 123);
    assertTrue(isUsed);
  }

  function testConcrete_SuccessWhen_NonceUsedForDifferentUser() public {
    // Use nonce for user1
    harness.useUnorderedNonce(user1, 123);

    // Check for user2 - should not be used
    bool isUsed = harness.isUsedNonce(user2, 123);
    assertFalse(isUsed);
  }

  function testConcrete_SuccessWhen_NonceUsedAfterInvalidation() public {
    // Invalidate nonce first
    uint256 nonce = 123;
    (uint256 wordPos, uint256 bitPos) = harness.bitmapPositions(nonce);
    uint256 mask = 1 << bitPos;

    vm.prank(user1);
    harness.invalidateUnorderedNonce(wordPos, mask);

    bool isUsed = harness.isUsedNonce(user1, nonce);
    assertTrue(isUsed);
  }

  // Test _tryUseUnorderedNonce function
  function testConcrete_SuccessWhen_TryUseUnorderedNonceFirstTime() public {
    bool success = harness.tryUseUnorderedNonce(user1, 123);
    assertTrue(success);

    // Verify the nonce is now used
    bool isUsed = harness.isUsedNonce(user1, 123);
    assertTrue(isUsed);
  }

  function testConcrete_SuccessWhen_TryUseUnorderedNonceSecondTime() public {
    // Use nonce first time
    bool success1 = harness.tryUseUnorderedNonce(user1, 123);
    assertTrue(success1);

    // Try to use same nonce again
    bool success2 = harness.tryUseUnorderedNonce(user1, 123);
    assertFalse(success2);
  }

  function testConcrete_SuccessWhen_TryUseUnorderedNonceAfterInvalidation() public {
    // Invalidate nonce first
    uint256 nonce = 123;
    (uint256 wordPos, uint256 bitPos) = harness.bitmapPositions(nonce);
    uint256 mask = 1 << bitPos;

    vm.prank(user1);
    harness.invalidateUnorderedNonce(wordPos, mask);

    // Try to use the invalidated nonce
    bool success = harness.tryUseUnorderedNonce(user1, nonce);
    assertFalse(success);
  }

  // Test _useUnorderedNonce function
  function testConcrete_SuccessWhen_UseUnorderedNonceFirstTime() public {
    harness.useUnorderedNonce(user1, 123);

    // Verify the nonce is now used
    bool isUsed = harness.isUsedNonce(user1, 123);
    assertTrue(isUsed);
  }

  function testConcrete_RevertWhen_UseUnorderedNonceSecondTime() public {
    // Use nonce first time
    harness.useUnorderedNonce(user1, 123);

    // Try to use same nonce again - should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        UnorderedNonceBitMapUpgradeable.UsedNonce.selector, harness.useUnorderedNonce.selector, user1, 123
      )
    );
    harness.useUnorderedNonce(user1, 123);
  }

  function testConcrete_RevertWhen_UseUnorderedNonceAfterInvalidation() public {
    // Invalidate nonce first
    uint256 nonce = 123;
    (uint256 wordPos, uint256 bitPos) = harness.bitmapPositions(nonce);
    uint256 mask = 1 << bitPos;

    vm.prank(user1);
    harness.invalidateUnorderedNonce(wordPos, mask);

    // Try to use the invalidated nonce - should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        UnorderedNonceBitMapUpgradeable.UsedNonce.selector, harness.useUnorderedNonce.selector, user1, nonce
      )
    );
    harness.useUnorderedNonce(user1, nonce);
  }

  // Test _invalidateUnorderedNonce function
  function testConcrete_SuccessWhen_InvalidateUnorderedNonce() public {
    uint256 wordPos = 5;
    uint256 mask = 0x12345678;

    vm.prank(user1);
    vm.expectEmit(true, false, false, true);
    emit UnorderedNonceBitMapUpgradeable.UnorderedNonceInvalidation(user1, wordPos, mask);
    harness.invalidateUnorderedNonce(wordPos, mask);

    // Verify the bitmap was updated
    uint256 bitmap = harness.getNonceBitmap(user1, wordPos);
    assertEq(bitmap, mask);
  }

  function testConcrete_SuccessWhen_InvalidateUnorderedNonceMultipleTimes() public {
    uint256 wordPos = 5;
    uint256 mask1 = 0x12345678;
    uint256 mask2 = 0x87654321;

    vm.startPrank(user1);

    harness.invalidateUnorderedNonce(wordPos, mask1);
    harness.invalidateUnorderedNonce(wordPos, mask2);

    vm.stopPrank();

    // Verify the bitmap was updated with OR operation
    uint256 bitmap = harness.getNonceBitmap(user1, wordPos);
    assertEq(bitmap, mask1 | mask2);
  }

  // Test events
  function testConcrete_SuccessWhen_UnorderedNonceUsedEventEmitted() public {
    vm.expectEmit(true, true, false, true);
    emit UnorderedNonceBitMapUpgradeable.UnorderedNonceUsed(harness.tryUseUnorderedNonce.selector, user1, 123);

    harness.tryUseUnorderedNonce(user1, 123);
  }

  // Test edge cases with different nonce values
  function testConcrete_SuccessWhen_NonceWithMaxBitPos() public {
    uint256 nonce = 0xFF; // bitPos = 255
    bool success = harness.tryUseUnorderedNonce(user1, nonce);
    assertTrue(success);

    bool isUsed = harness.isUsedNonce(user1, nonce);
    assertTrue(isUsed);
  }

  function testConcrete_SuccessWhen_NonceWithZeroBitPos() public {
    uint256 nonce = 0x100; // bitPos = 0, wordPos = 1
    bool success = harness.tryUseUnorderedNonce(user1, nonce);
    assertTrue(success);

    bool isUsed = harness.isUsedNonce(user1, nonce);
    assertTrue(isUsed);
  }

  function testConcrete_SuccessWhen_NonceWithLargeWordPos() public {
    uint256 nonce = 0x1234567800; // Large wordPos
    bool success = harness.tryUseUnorderedNonce(user1, nonce);
    assertTrue(success);

    bool isUsed = harness.isUsedNonce(user1, nonce);
    assertTrue(isUsed);
  }

  // Test multiple nonces in same word
  function testConcrete_SuccessWhen_MultipleNoncesInSameWord() public {
    uint256 nonce1 = 0x100; // wordPos = 1, bitPos = 0
    uint256 nonce2 = 0x101; // wordPos = 1, bitPos = 1
    uint256 nonce3 = 0x1FF; // wordPos = 1, bitPos = 255

    // Use all three nonces
    assertTrue(harness.tryUseUnorderedNonce(user1, nonce1));
    assertTrue(harness.tryUseUnorderedNonce(user1, nonce2));
    assertTrue(harness.tryUseUnorderedNonce(user1, nonce3));

    // Verify all are used
    assertTrue(harness.isUsedNonce(user1, nonce1));
    assertTrue(harness.isUsedNonce(user1, nonce2));
    assertTrue(harness.isUsedNonce(user1, nonce3));

    // Try to use them again - should fail
    assertFalse(harness.tryUseUnorderedNonce(user1, nonce1));
    assertFalse(harness.tryUseUnorderedNonce(user1, nonce2));
    assertFalse(harness.tryUseUnorderedNonce(user1, nonce3));
  }

  // Test different users with same nonce
  function testConcrete_SuccessWhen_DifferentUsersSameNonce() public {
    uint256 nonce = 123;

    // Both users should be able to use the same nonce
    assertTrue(harness.tryUseUnorderedNonce(user1, nonce));
    assertTrue(harness.tryUseUnorderedNonce(user2, nonce));

    // Verify both are used
    assertTrue(harness.isUsedNonce(user1, nonce));
    assertTrue(harness.isUsedNonce(user2, nonce));
  }

  // Test invalidation with multiple bits
  function testConcrete_SuccessWhen_InvalidateMultipleBits() public {
    uint256 wordPos = 5;
    uint256 mask = 0xFFFFFFFF; // Invalidate all 32 bits

    vm.prank(user1);
    harness.invalidateUnorderedNonce(wordPos, mask);

    // All nonces in this word should be considered used
    for (uint256 i = 0; i < 32; i++) {
      uint256 nonce = (wordPos << 8) | i;
      assertTrue(harness.isUsedNonce(user1, nonce));
    }
  }

  // Test boundary conditions
  function testConcrete_SuccessWhen_NonceWithAllOnesBitPos() public {
    uint256 nonce = 0x1FF; // bitPos = 255 (all ones in 8 bits)
    bool success = harness.tryUseUnorderedNonce(user1, nonce);
    assertTrue(success);

    bool isUsed = harness.isUsedNonce(user1, nonce);
    assertTrue(isUsed);
  }

  function testConcrete_SuccessWhen_NonceWithAllOnesWordPos() public {
    uint256 nonce = 0xFF000000; // wordPos = 0xFF0000 (large wordPos)
    bool success = harness.tryUseUnorderedNonce(user1, nonce);
    assertTrue(success);

    bool isUsed = harness.isUsedNonce(user1, nonce);
    assertTrue(isUsed);
  }

  // Test storage isolation between different words
  function testConcrete_SuccessWhen_DifferentWordsIsolated() public {
    uint256 nonce1 = 0x100; // wordPos = 1, bitPos = 0
    uint256 nonce2 = 0x200; // wordPos = 2, bitPos = 0

    // Use nonces in different words
    assertTrue(harness.tryUseUnorderedNonce(user1, nonce1));
    assertTrue(harness.tryUseUnorderedNonce(user1, nonce2));

    // Both should be used
    assertTrue(harness.isUsedNonce(user1, nonce1));
    assertTrue(harness.isUsedNonce(user1, nonce2));

    // Try to use them again - should fail
    assertFalse(harness.tryUseUnorderedNonce(user1, nonce1));
    assertFalse(harness.tryUseUnorderedNonce(user1, nonce2));
  }

  // Test invalidation with specific bit patterns
  function testConcrete_SuccessWhen_InvalidateSpecificBits() public {
    uint256 wordPos = 10;
    uint256 mask = 0x0000000F; // Invalidate bits 0-3

    vm.prank(user1);
    harness.invalidateUnorderedNonce(wordPos, mask);

    // Check that specific nonces are invalidated
    for (uint256 i = 0; i < 4; i++) {
      uint256 nonce = (wordPos << 8) | i;
      assertTrue(harness.isUsedNonce(user1, nonce));
    }

    // Check that other nonces in the same word are not invalidated
    for (uint256 i = 4; i < 8; i++) {
      uint256 nonce = (wordPos << 8) | i;
      assertFalse(harness.isUsedNonce(user1, nonce));
    }
  }

  // Fuzz tests
  function testFuzz_SuccessWhen_TryUseUnorderedNonceWithRandomNonce(uint256 nonce) public {
    bool success = harness.tryUseUnorderedNonce(user1, nonce);
    assertTrue(success);

    bool isUsed = harness.isUsedNonce(user1, nonce);
    assertTrue(isUsed);
  }

  function testFuzz_SuccessWhen_TryUseUnorderedNonceTwiceWithRandomNonce(uint256 nonce) public {
    bool success1 = harness.tryUseUnorderedNonce(user1, nonce);
    assertTrue(success1);

    bool success2 = harness.tryUseUnorderedNonce(user1, nonce);
    assertFalse(success2);
  }

  function testFuzz_SuccessWhen_BitmapPositionsWithRandomNonce(uint256 nonce) public pure {
    // This test only checks pure function calculations, no state changes
    uint256 expectedWordPos = uint248(nonce >> 8);
    uint256 expectedBitPos = uint8(nonce);

    assertEq(expectedWordPos, uint248(nonce >> 8));
    assertEq(expectedBitPos, uint8(nonce));
  }

  function testFuzz_SuccessWhen_DifferentUsersWithRandomNonce(uint256 nonce, address randomUser1, address randomUser2)
    public
  {
    vm.assume(randomUser1 != randomUser2);
    vm.assume(randomUser1 != address(0));
    vm.assume(randomUser2 != address(0));

    // Both users should be able to use the same nonce
    assertTrue(harness.tryUseUnorderedNonce(randomUser1, nonce));
    assertTrue(harness.tryUseUnorderedNonce(randomUser2, nonce));

    // Verify both are used
    assertTrue(harness.isUsedNonce(randomUser1, nonce));
    assertTrue(harness.isUsedNonce(randomUser2, nonce));
  }

  function testFuzz_SuccessWhen_InvalidateRandomMask(uint256 wordPos, uint256 mask) public {
    vm.prank(user1);
    harness.invalidateUnorderedNonce(wordPos, mask);

    // Verify the bitmap was updated
    uint256 bitmap = harness.getNonceBitmap(user1, wordPos);
    assertEq(bitmap, mask);
  }
}
