// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract UnorderedNonceBitMapUpgradeable {
  error UsedNonce(bytes4 sig, address from, uint256 nonce);

  event UnorderedNonceUsed(bytes4 indexed sig, address indexed from, uint256 nonce);
  /// @dev Emits an event when the owner successfully invalidates an unordered nonce.
  event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

  struct UnorderedNonceBitmapStorage {
    /// @dev Store the unordered nonce by address, inspired by SignatureTransfer contract of Uniswap.
    mapping(address => mapping(uint256 => uint256)) _nonceBitmap;
  }

  // keccak256(abi.encode(uint256(keccak256("ronin.storage.UnorderedNonceBitmap")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant UnorderedNonceBitmapStorageLocation =
    0x639e53e9f065f88f35351da50a7a338602f841a0bf1918d155fbc0b6e4e8e000;

  /// @dev Invalidate up to 256 nonces in a single transaction.
  function _invalidateUnorderedNonce(uint256 wordPos, uint256 mask) internal {
    _getUnorderedNonceBitmapStorage()._nonceBitmap[msg.sender][wordPos] |= mask;

    emit UnorderedNonceInvalidation(msg.sender, wordPos, mask);
  }

  /// @dev Check if the nonce has been used before.
  function isUsedNonce(address from, uint256 nonce) public view returns (bool) {
    (uint256 wordPos, uint256 bitPos) = _bitmapPositions(nonce);
    uint256 bit = 1 << bitPos;
    uint256 flipped = _getUnorderedNonceBitmapStorage()._nonceBitmap[from][wordPos] ^ bit;
    return flipped & bit == 0;
  }

  /// @dev Mark the nonce as used, and revert if it has been used before.
  function _useUnorderedNonce(address from, uint256 nonce) internal {
    require(_tryUseUnorderedNonce(from, nonce), UsedNonce(msg.sig, from, nonce));
  }

  /// @dev Try to mark the nonce as used, return false if it has been used before.
  function _tryUseUnorderedNonce(address from, uint256 nonce) internal returns (bool) {
    UnorderedNonceBitmapStorage storage $ = _getUnorderedNonceBitmapStorage();
    (uint256 wordPos, uint256 bitPos) = _bitmapPositions(nonce);
    uint256 bit = 1 << bitPos;
    uint256 flipped = $._nonceBitmap[from][wordPos] ^ bit;

    if (flipped & bit != 0) {
      $._nonceBitmap[from][wordPos] = flipped;
      emit UnorderedNonceUsed(msg.sig, from, nonce);
      return true;
    }

    return false;
  }

  function _bitmapPositions(uint256 nonce) private pure returns (uint256 wordPos, uint256 bitPos) {
    wordPos = uint248(nonce >> 8);
    bitPos = uint8(nonce);
  }

  function _getUnorderedNonceBitmapStorage() private pure returns (UnorderedNonceBitmapStorage storage $) {
    assembly {
      $.slot := UnorderedNonceBitmapStorageLocation
    }
  }
}
