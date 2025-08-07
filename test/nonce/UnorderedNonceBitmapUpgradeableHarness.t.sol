// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Test } from "../../dependencies/forge-std-1.8.2/src/Test.sol";
import { UnorderedNonceBitMapUpgradeable } from "src/nonce/UnorderedNonceBitmapUpgradeable.sol";

contract UnorderedNonceBitmapUpgradeableHarness is UnorderedNonceBitMapUpgradeable {
  bytes32 private constant __location = 0x639e53e9f065f88f35351da50a7a338602f841a0bf1918d155fbc0b6e4e8e000;

  function getNonceBitmap(address from, uint256 wordPos) public view returns (uint256) {
    UnorderedNonceBitmapStorage storage $;
    assembly {
      $.slot := __location
    }
    return $._nonceBitmap[from][wordPos];
  }

  // Expose internal functions for testing
  function invalidateUnorderedNonce(uint256 wordPos, uint256 mask) public {
    _invalidateUnorderedNonce(wordPos, mask);
  }

  function useUnorderedNonce(address from, uint256 nonce) public {
    _useUnorderedNonce(from, nonce);
  }

  function tryUseUnorderedNonce(address from, uint256 nonce) public returns (bool) {
    return _tryUseUnorderedNonce(from, nonce);
  }

  // Helper function to calculate bitmap positions manually
  function bitmapPositions(uint256 nonce) public pure returns (uint256 wordPos, uint256 bitPos) {
    wordPos = uint248(nonce >> 8);
    bitPos = uint8(nonce);
  }
}
