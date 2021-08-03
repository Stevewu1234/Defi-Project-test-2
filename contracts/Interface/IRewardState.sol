interface IRewardState {
    function getReward(address player, uint _rewardSaveDuration) external;

    function earned(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint);

    function getRewardDistribution() external view returns (address);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);
}