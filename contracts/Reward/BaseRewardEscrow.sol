// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/zeppelin/Ownable.sol";
import "../Tools/CacheResolver.sol";

// Libraries
import "../Libraries/SafeMath.sol";

// Internal References
import "../Interface/IRewardToken.sol";
import "../Interface/ISystemStatus.sol";
import "../Interface/IRewardState.sol";
import "../Tools/zeppelin/IERC20.sol";

contract BaseRewardEscrow is Ownable,CacheResolver {
    using SafeMath for uint;

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

    /** Escrow Related Variables */ 

    // detail of an escrow event
    struct accountEscrowed {
        uint escrowedEndTime;
        uint escrowedAmount;
    }
    // an account's escrowed token recording
    mapping (address => mapping(uint => accountEscrowed)) public accountEscrowedEvent;

    // an account's escrow event entries
    mapping (address => uint256[]) public accountEscrowedEntries;

    // an account's total Escrowed token amount
    mapping(address => uint256) public accountTotalEscrowedBalance;

    // total Escrowedtoken in this Escrow Contract
    uint public totalEscrowedBalance;

    // users are not allowed to escrow too much which may encounter unbounded iteration over release
    uint public max_escrowNumber;

    // num of all escrow events in this Escrow Contract and it can be used to generate the next escrow event of an account
    uint public nextEntry;

    /** Vest Related Variables */ 

    // detail of an vest event
    struct accountReleased {
        uint releasedAcquiredTime;
        uint totalReleasedAmount;
    }

    // an account's total Released token amount
    mapping(address => accountReleased) public accountTotalReleasedBalance;



    // duration
    uint public max_escrowduration;

    uint public min_escrowduration;

    //todo the max_escrowduration and min_escrowduration can be defined in RewardState.

    constructor (address _resolver, uint _max_escrowNumber) CacheResolver(_resolver) {
        nextEntry = 1;
        max_escrowNumber = _max_escrowNumber;
    }


    /** ========== public view functions ========== */
    function accountEscrowedEndTime(address account) public view returns (uint) {
        return escrowedEntry.escrowedEndTime;
    }

    function accountEscorwedAmount(address account) public view returns (uint) {
        return escrowedEntry.escrowedAmount;
    }

    function accountReleasedAcquiredTime(address account) public view returns (uint) {
        return accountReleased.acquiredTime;
    }

    function accountReleasedTotalReleasedAmount(address account) public view returns (uint) {
        return accountReleased.totalReleasedAmount;
    }



    /** ========== external mutative functions ========== */

    // /**
    //  * @description: user can check all of the escrowed token he has and claim all of them once
    //  * @param receiver who receive escrowed token and the owner of escrowed token can authorize another user to claim
    //  * @return {*}
    //  */    
    // function vest(address receiver, uint[] memory entryIDs) external vestActive {

    //     // todo judge the receiver is the owner of these entried or not and get the authorization or not.

    //     uint256 total;
    //     for (uint i = 0; i < entryIDs.length; i++) {
    //         accountEscrowed storage entry = accountEscrowedEvent[receiver][entryIDs[i]];

    //         /* Skip entry if escrowAmount == 0 already vested */
    //         if (entry.escrowedAmount != 0) {
    //             uint256 amount = _claimableAmount(entry);

    //             /* update entry to remove escrowAmount */
    //             if (amount > 0) {
    //                 entry.escrowedAmount = 0;
    //             }

    //             /* add quantity to total */
    //             total = total.add(amount);
    //         }
    //     }
    //     if(total != 0) {
    //         _vest(receiver, amount);
    //     }
    // }

    function release(address receiver) external vestActive {
        for (uint i = 0; i < accountEscrowednum(); i++) {
            accountEscrowed storage entry = accountEscrowedEvent[receiver][accountEscrowedEntries[account][i]];

            /* Skip entry if escrowAmount == 0 already released */
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
            _release(receiver, amount);
        }
    }

    /**
     * @description: the function call will be limited by another contract of this system for restricting users add escrow entries at their will.
     * @param account the account to append a new escrow entry
     * @param amount escrowed amount 
     * @param duration user can customize the duration but need to accord with min duration and max duration
     */    
    function appendEscrowEntry(address account, uint amount, uint duration) external {
        _appendEscrowEntry(account, amount, duration);

    }

    /** ========== OnlyOwner external mutative functions ========== */

    function updateDuration(uint min_escrowduration_, uint max_escrowduration_) external OnlyOwner {
        min_escrowduration min_escrowduration_;
        max_escrowduration = max_escrowduration_;
    }

    /** ========== external view functions ========== */
    
    function accountEscrowednum(address account) external view returns(uint num) {
        return num = accountEscrowedEntries[account].length;
    }

    function escrowedTokenBalanceOf(address account) external view returns(uint amount) {
        return accountTotalEscrowedBalance[account];
    }

    /** ========== internal mutative functions ========== */

    function _release(address receiver, uint _amount) internal {
        require(_amount <= IERC20(address(RewardToken())).balanceOf(address(this)), "there are not enough token to release");
        _reduceAccountEscrowedBalance(receiver, amount);
        _updateAccountReleasedEntry(receiver, amount);
        IERC20(address(RewardToken())).transfer(receiver, _amount);
        emit released(receiver, _amount);
    }

    //todo user can choose to vest their token which is not staked into the contract or vest those have been staked into contract. 
    //     if the vesting token have been staked into contract that maybe I need to provide a new function that vest and stake the token immediately.

    function _appendEscrowEntry(address account, uint _amount, uint duration) internal {
        require(duration >= min_escrowduration && duration <= max_escrowduration, "you must set the duration between allowed duration");
        require(accountEscrowednum() <= max_escrowNumber, "you have escrowed too much, we suggest you wait for your first escrowed token released");

        _addAccountEscrowedBalance(account, _amount);

        uint EndTime = block.timestamp + duration;
        uint entryID = nextEntry;

        accountEscrowedEvent[account][entryID] = accountEscrowed({escrowedEndTime: EndTime, escrowedAmount:_amount});
        accountEscrowedEntries[account].push(entryID);

        nextEntry = nextEntry.add(1);

        emit appendEscrowEntry(account, _amount, duration);
        
    }

    //todo add a internal function to calculate the locked reward of token, the longer they lock, the more they get. 
    //     and the function call is not from this contract, it will call a reward contract to modify some variables to calculate the reward.
    //     but this reward calculation will be confused becase all of the confirmed reward have been lock in this contract. If there is a new reward
    //     from this lock duration that will need to create a new escrow event. That will generate new confusion.


    function _addAccountEscrowedBalance(address account, uint _amount) internal {
        totalEscrowedBalance = totalEscrowedBalance.add(_amount);
        accountTotalEscrowedBalance[account] = accountTotalEscrowedBalance[account].add(_amount);
    }

    function _reduceAccountEscrowedBalance(address account, uint _amount) internal {
        totalEscrowedBalance = totalEscrowedBalance.sub(_amount);
        accountTotalEscrowedBalance[account] = accountTotalEscrowedBalance[account].sub(_amount);
    }

    function _updateAccountReleasedEntry(address account, uint amount) internal {
        accountTotalReleasedBalance[receiver].releasedAcquiredTime = block.timestamp;
        accountTotalReleasedBalance[receiver].totalReleasededAmount = accountTotalReleasedBalance[receiver].add(_amount);
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

    modifier releaseActive {
        systemStatue().requireSystemActive();
        systemStatue().requireFunctionActive(systemStatue().RELEASE, systemStatue().SECTION_REWARDPOOL);
    }

    //todo add a modifier to limit the function call of appendEscrowEntry must from a pointed contract
    //todo add a modifier to limit the function call of vest must from authorized user or the owner
 
    /** ========== event ========== */
    event released(address indexed receiver, uint indexed amount);
    event appendEscrowEntry(address indexed account, uint indexed amount, uint indexed duration);

}