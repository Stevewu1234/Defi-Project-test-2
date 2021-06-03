interface ILiquidityReward_Token_ETH {

    function stake(address account, uint256 amount) external;

    function withdraw(address account,uint256 amount) external;

    function getReward(address account) external;

    function exit(address account) external;

    function balanceOf(address account) external view returns (uint);

    function totalSupply() external view returns (uint);

    function earned(address account) external view returns (uint);

    function balanceOfStakeToken(address account) external view returns (uint);
}