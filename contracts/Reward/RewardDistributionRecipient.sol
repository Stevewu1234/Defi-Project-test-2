pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract RewardDistributionRecipient is Ownable {
    address rewardDistribution;

    

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}