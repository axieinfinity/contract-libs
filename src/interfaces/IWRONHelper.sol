// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWRONHelper {
  function WRON() external view returns (address);

  function withdraw(uint256 amount) external;

  function withdrawTo(address payable to, uint256 amount) external;
}
