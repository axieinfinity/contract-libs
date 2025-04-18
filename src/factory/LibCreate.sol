// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibCreate {
  /**
   * @dev Replace all the constructor arguments appended to the `creationCode` by `constructorArg` and deploy.
   */
  function createWithConstructorArguments(bytes memory creationCode, bytes memory constructorArg)
    internal
    returns (address addr)
  {
    assembly {
      let constructorSize := mload(constructorArg)
      let creationCodeSize := mload(creationCode)
      let offset := add(add(creationCode, 0x20), sub(creationCodeSize, constructorSize))

      let start := add(constructorArg, 0x20)
      for { let index := 0 } lt(index, constructorArg) { index := add(index, 0x20) } {
        mstore(add(offset, index), mload(add(start, index)))
      }
    }

    return createViaCreationCode(creationCode);
  }

  function createViaCreationCode(bytes memory creationCode) internal returns (address addr) {
    assembly {
      addr := create(0, add(0x20, creationCode), mload(creationCode))
    }
  }
}
