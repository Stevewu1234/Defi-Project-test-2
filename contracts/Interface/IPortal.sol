interface IPortal {

    // read functions
    function getTotalLockedAmount() external view returns (uint);

    function getAccountBalancesLockedAmount(address account) external view returns (uint);

    function getAccountEscrowedLockedAmount(address account) external view returns (uint);

    function getbalanceOfEscrowedAndAvailableAmount(address account) external view returns (uint);

    function getAccountTotalLockedAmount(address account) external view returns (uint accountTotalLockedAmount);

    function getTransferableAmount(address account) external view returns (uint transferable);

    // write functions
    function enter(address player, uint value, bool enterall) external;

    function withdraw(address player, uint value, bool withdrawall) external;

    function getReward(address player, uint _rewardSaveDuration) external;

    function exit(address player, uint value, bool withdrawall, uint _rewardSaveDuration) external;

    function transferEscrowedToBalancesLocked(address account, uint amount) external;

    function updateAccountEscrowedAndAvailableAmount(address account, uint amount, bool add, bool sub) external;

    function onlyExitAccountEscrowedLockedAmount(address account, uint amount) external;
}