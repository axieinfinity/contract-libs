// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibCreate {
  /**
   * NOTE: Only use it in case the contract DO NOT contain any immutables variables
   * Since the runtime code is already include the value of those variables and it's hard to directly replace them.
   */
  function createViaRuntimeCode(bytes memory runtimeCode, bytes memory constructorArg) internal returns (address addr) {
    bytes memory creationCode = abi.encodePacked(runtimeCode, constructorArg);

    return createViaCreationCode(creationCode);
  }

  function createViaCreationCode(bytes memory creationCode) internal returns (address addr) {
    assembly {
      addr := create(0, add(0x20, creationCode), mload(creationCode))
    }
  }
}
