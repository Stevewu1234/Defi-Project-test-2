pragma solidity >=0.6.0;

interface IUniswapV2Pair {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}