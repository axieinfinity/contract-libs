// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibCaller {
  function isCallerContract() internal view returns (bool yes) {
    yes = !isCallerEOA();
  }

  function isCallerEOA() internal view returns (bool yes) {
    assembly {
      yes := iszero(eq(caller(), origin()))
    }
  }

  function isCallerPayable() internal returns (bool yes) {
    
  }
}
