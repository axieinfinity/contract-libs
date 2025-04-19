// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibRandomizer {
  error ErrCeilingNotHigherThanFloor(uint256 floor, uint256 ceiling);

  /**
   * @dev Returns a random value in range [0, upper)
   */
  function random(uint256 upper, uint256[1] memory seed) internal pure returns (uint256 result) {
    result = seed[0] % upper;
    seed[0] = uint256(keccak256(abi.encodePacked(seed[0])));
  }

  /**
   * @dev Returns a random value in range [floor, ceiling], i.e the range is inclusive.
   * When floor == ceiling = `x`, the random result always be equal to `x`.
   */
  function randomRange(uint256 floor, uint256 ceiling, uint256[1] memory seed) internal pure returns (uint256) {
    if (floor > ceiling) revert ErrCeilingNotHigherThanFloor(floor, ceiling);
    return floor + random(ceiling - floor + 1, seed);
  }
}
