interface ISystemStatus {


    // global access list controller
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);


    // Be similar with the feature of requir(), the following function is used to check whether the section is active or not.
    function requireSystemActive() external view;

    function requireRewardPoolActive() external view;

    function requireCollectionTradingActive() external view;

    function requireActivitiesActive() external view;

    function requireStableCoinActive() external view;

    function requireDAOActive() external view;

    // status of key functions of each system section
    // function voterecordingActive() external view;

    function requireFunctionActive(bytes32 functionname, bytes32 section) external view;


    // whether tbe system is upgrading or not
    function isSystemUpgrading() external view returns (bool);
    
    // check the details of suspension of each section.
    function getSuspensionStatus(bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );

    function getFunctionSuspendstionStatus(bytes32 functionname, bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );


}