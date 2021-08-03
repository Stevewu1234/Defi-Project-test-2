interface IRewardEscrowUpgradeable {

    // read functions
    function accountEscrowedEndTime(address account, uint index) external view returns (uint);

    function accountEscorwedAmount(address account, uint index) external view returns (uint);

    function accountReleasedAcquiredTime(address account) external view returns (uint);

    function accountReleasedTotalReleasedAmount(address account) external view returns (uint);

    function escrowedTokenBalanceOf(address account) external view returns(uint amount);

    // write functions
    function appendEscrowEntry(address account, uint amount, uint duration) external;

    function release(address receiver, bool keepLocked) external;
}