/** This contract is referring to Synthetix but added new functions*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Inheritance
import "./RewardDistributionRecipient.sol";
import "./LPTokenWrapper.sol";

// Libraries
import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Internal References
import "../Libraries/Math.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiqudityReward is LPTokenWrapper, RewardDistributionRecipient{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public rewardtoken;      // token contract address

    uint256 public constant DURATION = 365 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    constructor (
        address _staketoken,
        address _rewardtoken
    )  {
        staketoken = IERC20(_staketoken);
        rewardtoken = IERC20(_rewardtoken);
    }


    /** ========== public mutative functions ========== */
    
    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(address account,uint256 amount) public override updateReward(account)  {
        require(amount > 0, "Cannot stake 0");
        super.stake(account,amount);
        emit Staked(account, amount);
    }

    function withdraw(address account, uint256 amount) public override updateReward(account)  {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(account,amount);
        emit Withdrawn(account, amount);
    }

    function exit(address account) public {
        withdraw(account,balanceOf(account));
        getReward(account);
    }

    function getReward(address account) public updateReward(account)  {
        uint256 reward = earned(account);
        if (reward > 0) {
            rewards[account] = 0;
            rewardtoken.safeTransfer(account, reward);
            emit RewardPaid(account, reward);
        }
    }

    /** ========== public view functions ========== */
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }
    
    function balanceOfStakeToken(address account) public view returns (uint) {
        return staketoken.balanceOf(account);
    }

    
    /** ========== Only authorized user ========== */
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


    /** ========== modifier ========== */

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
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
