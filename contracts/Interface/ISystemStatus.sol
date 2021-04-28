interface ISystemStatus {


    // global access list controller
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);


    // Be similar with the feature of requir(), the following function is used to check whether the section is active or not.
    function requireSystemActive() public view;

    function requireRewardPoolActive() public view;

    function requireCollectionTradingActive() public view;

    function requireActivitiesActive() public view;

    function requireStableCoinActive() public view;

    function requireDAOActive() public view;

    // status of key functions of each system section
    // function voterecordingActive() external view;

    function requireFunctionActive(string functionname, bytes32 section) external view;


    // whether tbe system is upgrading or not
    function isSystemUpgrading() public view returns (bool);
    
    // check the details of suspension of each section.
    function getSuspensionStatus(bytes32 section) public view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );

    function getFunctionSuspendstionStatus(string functionname, bytes32 section) public view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );


}