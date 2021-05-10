// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../Tools/CacheResolver.sol";

// Libraries
import "..";

// Internal References
import "../Interface/IRewardToken.sol";
import "../Interface/ISystemStatus.sol";
import "../Interface/IRewardState.sol";
import "../Tools/zeppelin/IERC20";

contract BaseRewardEscrow is Ownable,CacheResolver {
    // using SafeMath for uint;

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_REWARDTOKEN = "RewardToken"; 
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses[0] = CONTRACT_REWARDTOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_REWARDSTATE;
    }

    function rewardToken() internal view returns (IRewardToken) {
        return IRewardToken(requireAndGetAddress(CONTRACT_REWARDTOKEN));
    }

    function systemStatue() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function rewardState() internal view returns (IRewardState) {
        return IRewardState(requireAndGetAddress(CONTRACT_REWARDSTATE));
    }

    /** variables */
    struct accountEscrowed {
        uint escrowedEndTime;
        uint escrowedAmount;
    }

    struct accountVested {
        uint vestedAcquiredTime;
        uint totalVestedAmount;
    }

    mapping (address => mapping(uint => accountEscrowed)) public accountEscrowedEvent;

    mapping(address => uint256) public accountTotalEscrowedBalance;

    mapping(address => accountVested) public accountTotalVestedBalance;

    uint public totalEscrowedBalance;

    uint public max_escrowduration;

    uint public min_escrowduration;

    uint public currentEntry;


    /** ========== public view functions ========== */
    function accountEscrowedEndTime(address account) public view returns (uint) {
        return escrowedEntry.escrowedEndTime;
    }

    function accountEscorwedAmount(address account) public view returns (uint) {
        return escrowedEntry.escrowedAmount;
    }

    function accountVestedAcquiredTime(address account) public view returns (uint) {
        return accountVested.acquiredTime;
    }

    function accountVestedTotalVestedAmount(address account) public view returns (uint) {
        return accountVested.totalVestedAmount;
    }



    /** ========== external mutative functions ========== */

    function vest(address receiver, uint[] memory entryIDs) external vestActive {
        uint256 total;
        for (uint i = 0; i < entryIDs.length; i++) {
            accountEscrowed storage entry = accountEscrowed[receiver][entryIDs[i]];

            /* Skip entry if escrowAmount == 0 already vested */
            if (entry.escrowedAmount != 0) {
                uint256 amount = _claimableAmount(entry);

                /* update entry to remove escrowAmount */
                if (amount > 0) {
                    entry.escrowedAmount = 0;
                }

                /* add quantity to total */
                total = total.add(amount);
            }
        }
        if(total != 0) {
            _vest(receiver, amount);
        }
    }

    function appendEscrowEntry(address account, uint amount, uint duration) external {
        _appendEscrowEntry(account, amount, duration);

    }

    /** ========== OnlyOwner external mutative functions ========== */

    function updateDuration(uint min_escrowduration_, uint max_escrowduration_) external OnlyOwner {
        min_escrowduration min_escrowduration_;
        max_escrowduration = max_escrowduration_;
    }

    /** ========== external view functions ========== */
    
    function accountEscrowednum(address account)  external view returns(uint num) {
        return num = accountEscrowedEntryIds[account].length;
    }

    /** ========== internal mutative functions ========== */

    function _vest(address receiver, uint _amount) internal {
        require(_amount <= IERC20(address(RewardToken())).balanceOf(address(this)), "there are not enough token to vest");
        _reduceAccountEscrowedBalance(receiver, amount);
        _updateAccountVestedEntry(receiver, amount);
        IERC20(address(RewardToken())).transfer(receiver, _amount);
        emit vest(receiver, _amount);
    }

    function _appendEscrowEntry(address account, uint _amount, uint duration) internal {
        require(duration >= min_escrowduration && duration <= max_escrowduration, "you must set the duration between allowed duration");

        _addAccountEscrowedBalance(account, _amount);

        uint EndTime = block.timestamp + duration;
        uint entryID = currentEntry;

        accountEscrowedEvent[account][entryID] = accountEscrowed({escrowedEndTime: EndTime, escrowedAmount:_amount});

        currentEntry++;

        emit appendEscrowEntry(account, _amount, duration);
        
    }



    function _addAccountEscrowedBalance(address account, uint _amount) internal {
        totalEscrowedBalance = totalEscrowedBalance.add(_amount);
        accountTotalEscrowedBalance[account] = accountTotalEscrowedBalance[account].add(_amount);
    }

    function _reduceAccountEscrowedBalance(address account, uint _amount) internal {
        totalEscrowedBalance = totalEscrowedBalance.sub(_amount);
        accountTotalEscrowedBalance[account] = accountTotalEscrowedBalance[account].sub(_amount);
    }

    function _updateAccountVestedEntry(address account, uint amount) internal {
        accountTotalVestedBalance[receiver].vestedAcquiredTime = block.timestamp;
        accountTotalVestedBalance[receiver].totalVestedAmount = accountTotalVestedBalance[receiver].add(_amount);
    }

    /** ========== internal view functions ========== */

    function _claimableAmount(accountEscrowed memory _entry) internal view returns (uint) {
        uint256 amount;
        if (_entry.escrowedAmount != 0) {
            /* Escrow amounts claimable if block.timestamp equal to or after entry endTime */
            amount = block.timestamp >= _entry.escrowedEndTime ? _entry.escrowedAmount : 0;
        }
        return amount;
    }


    /** ========== modifier ========== */

    modifier vestActive {
        systemStatue().requireSystemActive();
        systemStatue().requireFunctionActive(systemStatue().VEST, systemStatue().SECTION_REWARDPOOL);
    }

 
    /** ========== event ========== */
    event vest(address indexed receiver, uint indexed amount);
    event appendEscrowEntry(address indexed account, uint indexed amount, uint indexed duration);

}