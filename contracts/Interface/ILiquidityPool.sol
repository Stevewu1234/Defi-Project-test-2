interface ILiquidityPool {
    function updateEarnings(address sender, uint value) external;
    
    function accountearnings(address account) external view returns (uint);
}