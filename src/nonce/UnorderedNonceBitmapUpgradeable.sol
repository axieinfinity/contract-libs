// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

abstract contract UnorderedNonceBitMapUpgradeable {
  error UsedNonce(bytes4 sig, address from, uint256 nonce);

  event UnorderedNonceUsed(bytes4 indexed sig, address indexed from, uint256 nonce);
  /// @dev Emits an event when the owner successfully invalidates an unordered nonce.
  event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

  struct UnorderedNonceBitmapStorage {
    /// @dev Store the unordered nonce by address, inspired by SignatureTransfer contract of Uniswap.
    mapping(address account => mapping(uint256 wordPos => uint256 bitPos)) _nonceBitmap;
  }

  // keccak256(abi.encode(uint256(keccak256("ronin.storage.UnorderedNonceBitmap")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant $$__UnorderedNonceBitmapStorageLocation =
    0x639e53e9f065f88f35351da50a7a338602f841a0bf1918d155fbc0b6e4e8e000;

  /// @dev Invalidate up to 256 nonces in a single transaction.
  function _invalidateUnorderedNonce(uint256 wordPos, uint256 mask) internal {
    _getUnorderedNonceBitmapStorage()._nonceBitmap[msg.sender][wordPos] |= mask;

    emit UnorderedNonceInvalidation(msg.sender, wordPos, mask);
  }

  /// @dev Check if the nonce has been used before.
  function isUsedNonce(address from, uint256 nonce) public view returns (bool) {
    (uint248 wordPos, uint8 bitPos) = _bitmapPositions(nonce);
    uint256 bitMask = _toBitMask(bitPos);
    uint256 flipped = _getUnorderedNonceBitmapStorage()._nonceBitmap[from][wordPos] ^ bitMask;
    return flipped & bitMask == 0;
  }

  /// @dev Mark the nonce as used, and revert if it has been used before.
  function _useUnorderedNonce(address from, uint256 nonce) internal {
    require(_tryUseUnorderedNonce(from, nonce), UsedNonce(msg.sig, from, nonce));
  }

  /// @dev Try to mark the nonce as used, return false if it has been used before.
  function _tryUseUnorderedNonce(address from, uint256 nonce) internal returns (bool) {
    UnorderedNonceBitmapStorage storage $ = _getUnorderedNonceBitmapStorage();
    (uint248 wordPos, uint8 bitPos) = _bitmapPositions(nonce);
    uint256 bitMask = _toBitMask(bitPos);
    uint256 flipped = $._nonceBitmap[from][wordPos] ^ bitMask;

    if (flipped & bitMask != 0) {
      $._nonceBitmap[from][wordPos] = flipped;
      emit UnorderedNonceUsed(msg.sig, from, nonce);
      return true;
    }

    return false;
  }

  /// @notice Returns the index of the bitmap and the bit position within the bitmap. Used for unordered nonces
  /// @param nonce The nonce to get the associated word and bit positions
  /// @return wordPos The word position or index into the nonceBitmap
  /// @return bitPos The bit position
  /// @dev The first 248 bits of the nonce value is the index of the desired bitmap
  /// @dev The last 8 bits of the nonce value is the position of the bit in the bitmap
  function _bitmapPositions(uint256 nonce) private pure returns (uint248 wordPos, uint8 bitPos) {
    wordPos = uint248(nonce >> 8);
    bitPos = uint8(nonce);
  }

  /// @dev Turn on the bit at the given position.
  function _toBitMask(uint8 bitPos) internal pure returns (uint256 mask) {
    mask = 1 << bitPos;
  }

  function _getUnorderedNonceBitmapStorage() private pure returns (UnorderedNonceBitmapStorage storage $) {
    assembly ("memory-safe") {
      $.slot := $$__UnorderedNonceBitmapStorageLocation
    }
  }
}
