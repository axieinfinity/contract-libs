// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IKatanaRouter {
  function factory() external pure returns (address);

  function WRON() external pure returns (address);

  function addLiquidity(
    address _tokenA,
    address _tokenB,
    uint256 _amountADesired,
    uint256 _amountBDesired,
    uint256 _amountAMin,
    uint256 _amountBMin,
    address _to,
    uint256 _deadline
  )
    external
    returns (
      uint256 _amountA,
      uint256 _amountB,
      uint256 _liquidity
    );

  function addLiquidityRON(
    address _token,
    uint256 _amountTokenDesired,
    uint256 _amountTokenMin,
    uint256 _amountRONMin,
    address _to,
    uint256 _deadline
  )
    external
    payable
    returns (
      uint256 _amountToken,
      uint256 _amountRON,
      uint256 _liquidity
    );

  function removeLiquidity(
    address _tokenA,
    address _tokenB,
    uint256 _liquidity,
    uint256 _amountAMin,
    uint256 _amountBMin,
    address _to,
    uint256 _deadline
  ) external returns (uint256 _amountA, uint256 _amountB);

  function removeLiquidityRON(
    address _token,
    uint256 _liquidity,
    uint256 _amountTokenMin,
    uint256 _amountRONMin,
    address _to,
    uint256 _deadline
  ) external returns (uint256 _amountToken, uint256 _amountRON);

  function removeLiquidityWithPermit(
    address _tokenA,
    address _tokenB,
    uint256 _liquidity,
    uint256 _amountAMin,
    uint256 _amountBMin,
    address _to,
    uint256 _deadline,
    bool _approveMax,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (uint256 _amountA, uint256 _amountB);

  function removeLiquidityRONWithPermit(
    address _token,
    uint256 _liquidity,
    uint256 _amountTokenMin,
    uint256 _amountRONMin,
    address _to,
    uint256 _deadline,
    bool _approveMax,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (uint256 _amountToken, uint256 _amountRON);

  function swapExactTokensForTokens(
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external returns (uint256[] memory _amounts);

  function swapTokensForExactTokens(
    uint256 _amountOut,
    uint256 _amountInMax,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external returns (uint256[] memory _amounts);

  function swapExactRONForTokens(
    uint256 _amountOutMin,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external payable returns (uint256[] memory _amounts);

  function swapTokensForExactRON(
    uint256 _amountOut,
    uint256 _amountInMax,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external returns (uint256[] memory _amounts);

  function swapExactTokensForRON(
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external returns (uint256[] memory _amounts);

  function swapRONForExactTokens(
    uint256 _amountOut,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external payable returns (uint256[] memory _amounts);

  function quote(
    uint256 _amountA,
    uint256 _reserveA,
    uint256 _reserveB
  ) external pure returns (uint256 _amountB);

  function getAmountOut(
    uint256 _amountIn,
    uint256 _reserveIn,
    uint256 _reserveOut
  ) external pure returns (uint256 _amountOut);

  function getAmountIn(
    uint256 _amountOut,
    uint256 _reserveIn,
    uint256 _reserveOut
  ) external pure returns (uint256 _amountIn);

  function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint256[] memory _amounts);

  function getAmountsIn(uint256 _amountOut, address[] calldata _path) external view returns (uint256[] memory _amounts);

  function removeLiquidityRONSupportingFeeOnTransferTokens(
    address _token,
    uint256 _liquidity,
    uint256 _amountTokenMin,
    uint256 _amountRONMin,
    address _to,
    uint256 _deadline
  ) external returns (uint256 _amountRON);

  function removeLiquidityRONWithPermitSupportingFeeOnTransferTokens(
    address _token,
    uint256 _liquidity,
    uint256 _amountTokenMin,
    uint256 _amountRONMin,
    address _to,
    uint256 _deadline,
    bool _approveMax,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (uint256 _amountRON);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external;

  function swapExactRONForTokensSupportingFeeOnTransferTokens(
    uint256 _amountOutMin,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external payable;

  function swapExactTokensForRONSupportingFeeOnTransferTokens(
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] calldata _path,
    address _to,
    uint256 _deadline
  ) external;
}
