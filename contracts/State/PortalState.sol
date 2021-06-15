// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/CacheResolverUpgradeable.sol";

// Internal References
import "../Interface/IToken.sol";
import "../Interface/IPortal.sol";
import "../Interface/IRewardEscrowUpgradeable.sol";

contract PortalState is OwnableUpgradeable, CacheResolver{

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_TOKEN = "Token";
    bytes32 private constant CONTRACT_PORTAL = "Portal";
    bytes32 private constant CONTRACT_REWARDESCROW = "RewardEscrow";

    function resolverAddressesRequired() public view override returns (bytes32[] memory ) {
        bytes32[] memory addresses = new bytes32[](3);
        addresses[0] = CONTRACT_TOKEN;
        addresses[1] = CONTRACT_PORTAL;
        addresses[2] = CONTRACT_REWARDESCROW;
        return addresses;
    }

    function token() internal view returns (IToken) {
        return IToken(requireAndGetAddress(CONTRACT_TOKEN));
    }

    function portal() internal view returns (IPortal) {
        return IPortal(requireAndGetAddress(CONTRACT_PORTAL));
    }

    function rewardEscrow() internal view returns (IRewardEscrowUpgradeable) {
        return IRewardEscrowUpgradeable(requireAndGetAddress(CONTRACT_REWARDESCROW));
    }



    /** =========== global variables ========== */
    uint internal PlayerCardAddress;

    uint internal totalplayers;

    uint internal totalLockedAmount;
    
    struct AttendanceData {
        uint attendRate;
        uint attendTime;
        uint ownedCardTokenID;
    }

    mapping (address => mapping(address => uint256)) public PlayerCardOwnership;

    mapping (address => AttendanceData) public Attendance;

    mapping (address => uint) internal accountBalancesLockedAmount;

    mapping (address => uint) internal accountEscrowedAndAvailableAmount;

    

    function portal_init(address _resolver, address _cardAddress) public initializer {
        __Ownable_init();
        _cacheInit(_resolver);
        EscrowedAndAvailableAmount[account] = 0;
        PlayerCardAddress = _cardAddress;
    }


    /** ========== public view functions ========== */
    function getTotalLockedAmount() public view returns (uint) {
        return totalLockedAmount;
    }

    function getAccountLockedAmount(address account) public view returns (uint) {
        return accountLockedAmount[account];
    }

    function balanceOfEscrowedAndAvailableAmount(address account) public view returns (uint) {
        return accountEscrowedAndAvailableAmount[account];
    }

    function getCardAddres() public view returns (address) {
        return PlayerCardAddress;
    }

    function getCardId(address account) public view returns (uint cardId) {
        return cardId = PlayerCardOwnership[account][PlayerCardAddress];
    }

    function accountAttendance(address account) public view returns (
        uint _attendRate,
        uint _attendTime,
        uint _ownedCardTokenID
    ) {
        _attendRate = Attendance[account].attendRate;
        _attendTime = Attendance[account].attendTime;
        _ownedCardTokenID = Attendance[account].ownedCardTokenID;

        return (_attendRate, _attendTime, _ownedCardTokenID);
    }



    /** ========== external mutative functions ========== */    
    function distributeCardOnwer(address _owner, uint256 _cardId) external onlyPortal {
        require(getCardId() == 0, "each player is only allowed to own one ID.");
        PlayerCardOwnership[_owner][PlayerCardAddress] = _cardId;
    }

    function appendAttnedanceData(address _owner, uint _attendRate, uint _ownedCardTokenID) external onlyPortal {
        require(_owner != address(0) && _attendRate != 0, "please record correct data");
        Attendance[_owner].attendRate = _attendRate;
        Attendance[_owner].attendTime = block.timestamp;
        Attendance[_owner].ownedCardTokenID = _ownedCardTokenID;
    }

    function updateAccountEscrowedAndAvailableAmount(address account, uint amount, bool add, bool sub) external onlyRewardEscrowAndPortal {
        _updateAccountEscrowedAndAvailableAmount(account, amount, add, sub);
    }

    function updateAccountBalancesLockedAmount(address account, uint amount, bool add, bool sub) external onlyPortal {
        _updateAccountBalancesLockedAmount(account, amount, add, sub);
    }

    function transferEscrowedToBalancesLocked(address account, uint amount) external onlyRewardEscrowAndPortal {
        _updateAccountEscrowedAndAvailableAmount(account, amount, false, true);
        _updateAccountBalancesLockedAmount(account, amount, true, false);
    }

    /** ========== external view functions ========== */

    function getTransferableAmount(address account, uint value) external view returns (uint transferable) {

        // transferable token will be only calculated from balances of user, excluding escrowed token,
        // becasue escrowed token is not allowed to transfer between wallet.
        uint acountlockedamount = accountBalancesLockedAmount[accunt];

        if( value <= acountlockedamount) {
            transferable = 0;
        } else {
            transferable = value - acountlockedamount;
        }
    }



    /** ========== internal mutative functions ========== */
    // update account escrowed token quota
    function _updateAccountEscrowedAndAvailableAmount(address account, uint amount, bool add, bool sub) internal {
        require(add != sub, "not allowed to be the same");
        

        if(add == true) {
            accountEscrowedAndAvailableAmount[account] = EscrowedAndAvailableAmount[account] + amount;
        }

        if(sub == true) {
            require(accountEscrowedAndAvailableAmount[account] >= amount, "you don't have enough escrowed token");
            accountEscrowedAndAvailableAmount[account] = EscrowedAndAvailableAmount[account] - amount;
        }
    }

        // update account balances 
    function _updateAccountBalancesLockedAmount(address account, uint updatingLockAmount, bool add, bool sub) internal {
        require(add != sub, "not allowed to be the same");

        if(add == true) {
            if(accountBalancesLockedAmount[account] == 0) {totalplayers++;}
            accountBalancesLockedAmount[account] += _increaseAmount;

            totalLockedAmount += _increaseAmount;
        }

        if(sub == true) {
            accountBalancesLockedAmount[account] -= _decreaseAmount;
            if(accountBalancesLockedAmount[account] == 0) {totalplayers--;}

            totalLockedAmount -= _decreaseAmount;
        }
    }



    /** ========== internal view functions ========== */
    function _percapitalshareof() internal {}










    /** ========== private mutative functions ========== */


    /** ========== modifier ========== */
    modifier onlyPortal() {
        require(address(portal()) == _msgSender(), "only portal contract can access");
        _;
    }

    modifier onlyRewardEscrowAndPortal() {
        require(address(rewardEscrow()) == _msgSender() && address(portal()) == _msgSender(), "only rewardEscrow contract can access");
        _;
    }




    /** ========== event ========== */
    

}