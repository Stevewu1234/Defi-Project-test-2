// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/CacheResolverUpgradeable.sol";

// Libraries
import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../node_modules/@openzeppelin/contracts/utils/math/Math.sol";

// Internal References
import "../Interface/IPortal.sol";
import "../Interface/IRewardEscrowUpgradeable.sol";
import "../Interface/IToken.sol";

contract RewardState is OwnableUpgradeable, CacheResolverUpgradeable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;


    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_PORTAL= "Portal";
    bytes32 private constant CONTRACT_REWARDESCROWUPGRADEABLE = "RewardEscrowUpgradeable";
    bytes32 private constant CONTRACT_TOKEN = "Token";

    function resolverAddressesRequired() public view override returns (bytes32[] memory ) {
        bytes32[] memory addresses = new bytes32[](3);
        addresses[0] = CONTRACT_PORTAL;
        addresses[1] = CONTRACT_REWARDESCROWUPGRADEABLE;
        addresses[2] = CONTRACT_TOKEN;
        return addresses;
    }

    function portal() internal view returns (IPortal) {
        return IPortal(requireAndGetAddress(CONTRACT_PORTAL));
    }   

    function rewardEscrowUpgradeable() internal view returns (IRewardEscrowUpgradeable) {
        return IRewardEscrowUpgradeable(requireAndGetAddress(CONTRACT_REWARDESCROWUPGRADEABLE));
    }

    function token() internal view returns (IToken) {
        return IToken(requireAndGetAddress(CONTRACT_TOKEN));
    }

    /** ========== variables ========== */
    uint256 public constant DURATION = 365 days;

    address internal rewardDistribution;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    function rewardState_init(address _resolver, address _rewardDistribution) external initializer {
        __Ownable_init();
        _cacheInit(_resolver);
        rewardDistribution = _rewardDistribution;
    }

    /** ========== public view functions ========== */
    function getRewardDistribution() public view returns (address) {
        return rewardDistribution;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (portal().getTotalLockedAmount() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(portal().getTotalLockedAmount())
            );
    }

    function balanceOf(address account) public view returns (uint) {
        return portal().getAccountTotalLockedAmount(account);
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }


    /** ========== external mutative functions ========== */

    function getReward(address account, uint _rewardSaveDuration) external updateReward(account) onlyInternalContract returns (uint) {
        uint256 reward = earned(account);
        if (reward > 0) {
            rewards[account] = 0;
            rewardEscrowUpgradeable().appendEscrowEntry(account, reward, _rewardSaveDuration);
            emit RewardPaid(account, reward);
        }
        require(token().transfer(address(rewardEscrowUpgradeable()), reward), "there are no enough token to transfer");
        return reward;
    }

    function notifyRewardAmount(uint256 reward)    //reward amount notification
        external 
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }

    /** ========== modifier ========== */

    modifier onlyInternalContract() {
        require(_msgSender() == address(portal()), "only internal contract can access");
        _;
    }

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /** ========== event ========== */
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
}