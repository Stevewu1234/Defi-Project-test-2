pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../Interface/ISystemStatus.sol";


contract SystemStatus is Ownable {

    struct Sectionstatus {
        bool canSuspend;
        bool canResume;
    }

    struct functionstatus {
        string functionname;
        bytes32 section;
        bool canSuspend;
        bool canResume;
    }

    mapping(bytes32 => mapping(address => Sectionstatus)) public SectionAccessControl;
    mapping(string => mapping(address => functionstatus)) public FunctionAccessControl;

    struct Suspendsion {
        bool suspended;
        // refer to synthetix's design 
        // 0 => no reason, 1 => upgrading, 2 => accident, 3+ => defined by system usage
        uint8 reason;
        uint timestamp;
        address operator;
    }
    mapping(bytes32 => Suspendsion) public SectionSuspendsionStatus;
    mapping(string => mapping (bytes32 => Suspendsion)) public FunctionSuspendsionStatus;

    // Suspension public systemSuspension;
    // Suspension public RewardPoolSuspension;
    // Suspension public CollectionTradingSuspension;
    // Suspension public ActivitiesSuspension;
    // Suspension public StableCoinSuspension;
    // Suspension public DAOSuspension;

    uint public delay;

    uint248 public constant SUSPENSION_REASON_UPGRADE = 1;

    bytes32 public constant SECTION_SYSTEM = "System";
    bytes32 public constant SECTION_REWARDPOOL = "RewardPool";
    bytes32 public constant SECTION_COLLECTIONT_TRADING = "CollectionTrading";
    bytes32 public constant SECTION_ACTIVITIES = "Activities";
    bytes32 public constant SECTION_STABLECOIN = "StableCoin";
    bytes32 public constant SECTION_DAO = "DAO";

    // string public constant TokenMint = "tokenmint";
    // string public constant TokenBurn = "tokenburn";
    
    // constructor () {}

    /** ========== public view functions ========== */

    function isSystemUpgrading() public view returns (bool) {
        return systemSuspendsion.suspended && systemSuspendsion.reason == SUSPENSION_REASON_UPGRADE;
    }

    function getSectionSuspendsionStatus(bytes32 section) public view returns(
        bool suspended,
        uint reason,
        uint timestamp,
        address operator
        ) 
    {
        Suspendsion suspendsionStatus = SectionSuspendsionStatus[section];
        suspended = suspendsionStatus.suspended;
        reason = suspendsionStatus.reason;
        timestamp = suspendsionStatus.timestamp;
        operator = suspendsionStatus.operator;
    }
    
    function getFunctionSuspendstionStatus(string functionname, bytes32 section) public view returns(
        bool suspended,
        uint reason,
        uint timestamp,
        address operator
    )
    {
        Suspendsion suspendsionStatus = FunctionSuspendsionStatus[functionname][section];
        suspended = suspendsionStatus.suspended;
        reason = suspendsionStatus.reason;
        timestamp = suspendsionStatus.timestamp;
        operator = suspendsionStatus.operator;
    }


    function requireSystemActive() external view {
        _internalRequireSystemActive();
    }

    function requireRewardPoolActive() external view {
        _internalRequireSystemActive();
        _internalRequireRewardPoolActive();
    }

    function requireCollectionTradingActive() external view {
        _internalRequireSystemActive();
        _internalRequireCollectionTradingActive();
    }

    function requireActivitiesActive() external view {
        _internalRequireSystemActive();
        _internalRequireActivitiesActive();
    }

    function requireStableCoinActive() external view {
        _internalRequireSystemActive();
        _internalRequireStableCoinActive();
    }

    function requireDAOActive() external view {
        _internalRequireSystemActive();
        _internalRequireDAOActive();
    }


    /** ========== external mutative OnlyOwner functions ========== */

    // update section access list

    function updateSectionAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateSectionAccessControl(section, account, canSuspend, canResume);
    }

    function updateSectionAccessControls(
        bytes32[] calldata sections,
        address[] calldata accounts,
        bool[] calldata canSuspends,
        bool[] calldata canResumes
    ) external onlyOwner {
        require(
            sections.length == accounts.length &&
            accounts.length == canSuspends.length &&
            canSuspends.length == canResumes.length,
            "Input array lengths must match"
        );
        for (uint i = 0; i < sections.length; i++) {
            _internalUpdateSectionAccessControl(sections[i], accounts[i], canSuspends[i], canResumes[i]);
        }
    }

    // update function access list

    function updateFunctionAccessControl(
        string functionname,
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateFunctionAccessControl(functionname, section, account, canSuspend, canResume);
    }

    function updateFunctionAccessControls(
        string[] functionnames,
        bytes32[] sections,
        address[] accounts,
        bool[] canSuspends,
        bool[] canResumes
    ) external onlyOwner {
        require(
            functionnames.length == sections.length &&
            sections.length == accounts.length &&
            accounts.length == canSuspends.length &&
            canSuspends.length == canResumes.length,
            "Input array lengths must match"
        );
    for (uint i = 0; i < sections.length; i++) {
            _internalUpdateFunctionAccessControl(functionnames[i], sections[i], accounts[i], canSuspends[i], canResumes[i]);
        }
    }

    /** ========== external mutative functions ========== */


    function SectionSuspend(bytes32 section, uint reason) external {
        _internalSectionSuspend(section, reason);

        uint timestamp = SectionSuspendsionStatus[section].timestamp;
        if(section == SECTION_SYSTEM) { emit SystemSuspended(reason,timestamp,msg.sender);}
        else if(section == SECTION_REWARDPOOL) { emit RewardPoolSuspended(reason,timestamp,msg.sender);}
        else if(section == SECTION_COLLECTIONT_TRADING) { emit CollectionTradingSuspended(reason,timestamp,msg.sender);}
        else if(section == SECTION_ACTIVITIES) { emit ActivitiesSuspended(reason,timestamp,msg.sender);}
        else if(section == SECTION_STABLECOIN) { emit StableCoinSuspended(reason,timestamp,msg.sender);}
        else if(section == SECTION_DAO) { emit DAOSuspended(reason,timestamp,msg.sender);}
    }

    function SectionResume(bytes32 resume) external {
        _internalSectionResume(section);

        uint timestamp = SectionSuspendsionStatus[section].timestamp;
        if(section == SECTION_SYSTEM) { emit SystemResumed(timestamp, msg.sender);}
        else if(section == SECTION_REWARDPOOL) { emit RewardPoolResumed(timestamp, msg.sender);}
        else if(section == SECTION_COLLECTIONT_TRADING) { emit CollectionTradingResumed(timestamp, msg.sender);}
        else if(section == SECTION_ACTIVITIES) { emit ActivitiesResumed(timestamp, msg.sender);}
        else if(section == SECTION_STABLECOIN) { emit StableCoinResumed(timestamp, msg.sender);}
        else if(section == SECTION_DAO) { emit DAOResumed(timestamp, msg.sender);}
    }

    function FunctionSuspend(string functionname, bytes32 section, uint reason) external {
        _internalFunctionSuspend(functionname, section, reason);
        uint timestamp = FunctionSuspendsionStatus[functionname][msg.sender].timestamp;
        emit FunctionSuspended(functionname, section, reason, timestamp, msg.sender);
    }

    function FunctionResume(string functionname, bytes32 section) external {
        _internalFunctionResume(functionname, section);
        uint timestamp = FunctionSuspendsionStatus[functionname][msg.sender].timestamp;
        emit FunctionResumed(functionname, section, 0, timestamp, msg.sender);
    }
     

    /** ========== external view functions ========== */




    // function active requirement
    function requireFunctionActive(string functionname, bytes32 section) external view {
        if(section == SECTION_SYSTEM) { requireSystemActive(); }
        else if(section == SECTION_REWARDPOOL) { requireRewardPoolActive();}
        else if(section == SECTION_COLLECTIONT_TRADING) { requireCollectionTradingActive();}
        else if(section == SECTION_ACTIVITIES) { requireActivitiesActive();}
        else if(section == SECTION_STABLECOIN) { requireStableCoinActive();}
        else if(section == SECTION_DAO) { requireDAOActive();}

        _internalRequireFunctionActive(functionname,section);
    }






    /** ========== internal mutative functions ========== */

    // section internal suspend

    function _internalSectionSuspend(bytes32 section, uint reason) internal allownadmin {
        _requireSectionAccessToSuspend(section);
        _privateSectionSuspend(section, reason);

    }

    function _internalSectionResume(bytes32 section) internal allownadmin {
        _requireSectionAccessToResume(section);
        _privateSectionResume(section);
    }

    // function internal suspend

    function _internalFunctionSuspend(string functionname, bytes32 section, uint reason) internal allownadmin {
        _requireFunctionAccessToSuspend(functionname, section);
        _privateFunctionSuspend(fcuntion,section,reason);
    }

    function _internalFunctionResume(string functionname, bytes32 section) internal allownadmin {
        _requireFunctionAccessToResume(functionname, section);
        _privateFunctionResume(function, section);
    }

    // section access list update

    function _internalUpdateSectionAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal  {
        _privateUpdateSectionAccessControl(section, account, canSuspend,canResume);
    }

    // function access list update

    function _internalUpdateFunctionAccessControl(
        string functionname,
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal  {
        _privateUpdateFunctionAccessControl(functionname, section, account, canSuspend, canResume);
    }

    /** ========== internal view functions ========== */

    // section require access

    function _requireSectionAccessToSuspend(bytes32 section) internal view {
        require(SectionAccessControl[section][msg.sender].canSuspend, "Restricted to access control list");
    }

    function _requireSectionAccessToResume(bytes32 section) internal view {
        require(SectionAccessControl[section][msg.sender].canResume, "Restricted to access control list");
    }
    
    // function require access

    function _requireFunctionAccessToSuspend(string functionname, bytes32 section) internal view {
        require(
            section == SECTION_SYSTEM ||
            section == SECTION_REWARDPOOL ||
            section == SECTION_COLLECTIONT_TRADING ||
            section == SECTION_ACTIVITIES ||
            section == SECTION_STABLECOIN ||
            section == SECTION_DAO,
            "Invalid section supplied"
        );
        require(FunctionAccessControl[functionname][msg.sender].section == section, "the section of this function don't match");
        require(FunctionAccessControl[functionname][msg.sender].canSuspend, "Restricted to access control list");
    }

    function _requireFunctionAccessToResume(string functionname, bytes32 section) internal view {
        require(
            section == SECTION_SYSTEM ||
            section == SECTION_REWARDPOOL ||
            section == SECTION_COLLECTIONT_TRADING ||
            section == SECTION_ACTIVITIES ||
            section == SECTION_STABLECOIN ||
            section == SECTION_DAO,
            "Invalid section supplied"
        );
        require(FunctionAccessControl[functionname][msg.sender].section == section, "the section of this function don't match");
        require(FunctionAccessControl[functionname][msg.sender].canResume, "Restricted to access control list");
    }



    /** the following part is used to judge if each section of system is active or not. 
        that means the suspended is false or not. */


    function _internalRequireSystemActive() internal view {
        require(
            !SectionSuspendsionStatus(SECTION_SYSTEM).suspended,
            SectionSuspendsionStatus(SECTION_SYSTEM).reason == SUSPENSION_REASON_UPGRADE
                ? "system is upgrading, please wait"
                : "system is suspended. Operation prohibited"
        );
    }

    function _internalRequireRewardPoolActive() internal view {
        require(!SectionSuspendsionStatus(SECTION_REWARDPOOL).suspended, "RewardPool is suspended. Operation prohibited");
    }

    function _internalRequireCollectionTradingActive() internal view {
        require(!SectionSuspendsionStatus(SECTION_COLLECTIONT_TRADING).suspended, "Collection Trading is suspended. Operation prohibited");
    }

    function _internalRequireActivitiesActive() internal view {
        require(!SectionSuspendsionStatus(SECTION_ACTIVITIES).suspended, "Activities of system is suspended. Operation prohibited");
    }

    function _internalRequireStableCoinActive() internal view {
        require(!SectionSuspendsionStatus(SECTION_STABLECOIN).suspended, "Stable Coin section is suspended. Operation prohibited");
    }

    function _internalRequireDAOActive() internal view {
        require(!SectionSuspendsionStatus(SECTION_DAO).suspended, "DAO section is suspended. Operation prohibited");
    }



    /** the following part is used to judge if the function of each section of system is active or not. */

    function _internalRequireFunctionActive(string functionname, bytes32 section) internal view {
        require(!FunctionSuspendsionStatus[functionname, section], "the current function is suspended, Operation prohibited");
    }






    /** ========== private mutative functions ========== */

    // section private suspend

    function _privateSectionSuspend(bytes32 section, uint reason) private {
        SectionSuspendsionStatus[section].suspended = true;
        SectionSuspendsionStatus[section].reason = reason;
        SectionSuspendsionStatus[section].timestamp = block.timestamp;
        SectionSuspendsionStatus[section].operator = msg.sender;
    }

    function _privateSectionResume(bytes32 section) private {
        SectionSuspendsionStatus[section].suspended = false;
        SectionSuspendsionStatus[section].reason = 0;
        SectionSuspendsionStatus[section].timestamp = 0;
        SectionSuspendsionStatus[section].operator = address(0);
    }

    function _privateUpdateSectionAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) private {
        require(
            section == SECTION_SYSTEM ||
            section == SECTION_REWARDPOOL ||
            section == SECTION_COLLECTIONT_TRADING ||
            section == SECTION_ACTIVITIES ||
            section == SECTION_STABLECOIN ||
            section == SECTION_DAO,
            "Invalid section supplied"
        );
        SectionAccessControl[section][account].canSuspend = canSuspend;
        SectionAccessControl[section][account].canResume = canResume;
        emit SectionAccessControlUpdated(section, account, canSuspend, canResume);
    }

    // fucntion private suspend

    function _privateFunctionSuspend(string functionname, bytes32 section, uint reason) private {
        FunctionSuspendsionStatus[functionname][section].suspended = true;
        FunctionSuspendsionStatus[functionname][section].reason = reason;
        FunctionSuspendsionStatus[functionname][section].timestamp = block.timestamp;
        FunctionSuspendsionStatus[functionname][section].operator = msg.sender;
    }

    function _privateFunctionResume(string functionname, bytes32 section) private {
        FunctionSuspendsionStatus[functionname][section].suspended = false;
        FunctionSuspendsionStatus[functionname][section].reason = 0;
        FunctionSuspendsionStatus[functionname][section].timestamp = 0;
        FunctionSuspendsionStatus[functionname][section].operator = address(0);
    }

    function _privateUpdateFunctionAccessControl(
        string functionname,
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) private {
        require(
            section == SECTION_SYSTEM ||
            section == SECTION_REWARDPOOL ||
            section == SECTION_COLLECTIONT_TRADING ||
            section == SECTION_ACTIVITIES ||
            section == SECTION_STABLECOIN ||
            section == SECTION_DAO,
            "Invalid section supplied"
        );
        FunctionAccessControl[functionname][account].functionname = functionname;
        FunctionAccessControl[functionname][account].section = section;
        FunctionAccessControl[functionname][account].canSuspend = canSuspend;
        FunctionAccessControl[functionname][account].canResume = canResume;
        emit FunctionAccessControlUpdated(functionname,section,account,canSuspend,canResume);
    }

    /** ========== modifier ========== */
    modifier allownadmin() {
        require(owner() == msg.sender, "you're not the admin or authorized user");
        _;
    }

    /** ========== event ========== */
    event SectionAccessControlUpdated(bytes32 section, address account, bool canSuspend, bool canResume);
    event FunctionAccessControlUpdated(string functionname, bytes32 section, address account, bool canSuspend, bool canResume);

    event SystemSuspended(uint reason, uint timestamp, address operator);
    event RewardPoolSuspended(uint reason, uint timestamp, address operator);
    event CollectionTradingSuspended(uint reason, uint timestamp, address operator);
    event ActivitiesSuspended(uint reason, uint timestamp, address operator);
    event StableCoinSuspended(uint reason, uint timestamp, address operator);
    event DAOSuspended(uint reason, uint timestamp, address operator);

    event SystemResumed(uint timestamp, address operator);
    event RewardPoolResumed(uint timestamp, address operator);
    event CollectionTradingResumed(uint timestamp, address operator);
    event ActivitiesResumed(uint timestamp, address operator);
    event StableCoinResumed(uint timestamp, address operator);
    event DAOResumed(uint reason, uint timestamp, address operator);

    event FunctionSuspended(string functionname, bytes32 section, uint reason, uint timestamp, address operator);
    event FunctionResumed(string functionname, bytes32 section, uint reason, uint timestamp, address operator);
}