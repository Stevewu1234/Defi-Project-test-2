// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Tools/CacheResolver.sol";

// Internal References
import "./Interface/IMerkleDistribution.sol";
import "./Interface/ILiquidityReward_Token_ETH.sol";

contract SystemRouter is OwnableUpgradeable, CacheResolver{

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_MERKLEDISTRIBUTION = "MerkleDistribution";
    bytes32 private constant CONTRACT_LIQUIDITY_TOKEN_ETH = "LiquidityReward_Token_ETH";


    function resolverAddressesRequired() public view override returns (bytes32[] memory ) {
        bytes32[] memory addresses = new bytes32[](2);
        addresses[0] = CONTRACT_MERKLEDISTRIBUTION;
        addresses[1] = CONTRACT_LIQUIDITY_TOKEN_ETH;
        return addresses;
    }

    function merkleDistribution() internal view returns (IMerkleDistribution) {
        return IMerkleDistribution(requireAndGetAddress(CONTRACT_MERKLEDISTRIBUTION));
    }

    function liquidityReward_Token_ETH() internal view returns (ILiquidityReward_Token_ETH) {
        return ILiquidityReward_Token_ETH(requireAndGetAddress(CONTRACT_LIQUIDITY_TOKEN_ETH));
    }


    function router_init(address _resolver) public initializer {
        __Ownable_init();
        _cacheInit(_resolver);
    }
    
    /** ========== public view functions ========== */

    function stakedBalanceOf(address account) public view returns (uint) {
        return liquidityReward_Token_ETH().balanceOf(account);
    }

    function stakedTotalSupply() public view returns (uint) {
        return liquidityReward_Token_ETH().totalSupply();
    }

    function stakedEarned(address account) public view returns (uint) {
        return liquidityReward_Token_ETH().earned(account);
    }

    function balanceOfStakeToken(address account) public view returns (uint) {
        return liquidityReward_Token_ETH().balanceOfStakeToken(account);
    }

   function holderVaults(address account) public view returns (uint, uint) {
        (uint tokenamount, uint acquiretime) = merkleDistribution().holdertokenvaults(account);
        return (tokenamount, acquiretime);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        return merkleDistribution().isClaimed(index);
    }

    function ClaimedToken(address account) public view returns (uint) {
        return merkleDistribution().ClaimedToken(account);
    }

    /** ========== external mutative functions ========== */

    // Merkle
    function claim(uint256 index, address account, uint256 _amount, bytes32[] calldata merkleProof) external {
        merkleDistribution().claim(index, account, _amount, merkleProof);
    }

    function claimoflandholder(address _holder) external {
        merkleDistribution().claimoflandholder(_holder);
    }

    // Reward
    function stake(uint256 amount) external {
        liquidityReward_Token_ETH().stake(_msgSender(),amount);
    }

    function stakewithpermit(
        address stakingtoken,
        uint256 expiry, 
        uint value,
        uint8 v, 
        bytes32 r, 
        bytes32 s 
    ) public {
        IUniswapV2Pair(stakingtoken).permit(msg.sender, address(this), value, expiry, v, r, s);
        liquidityReward_Token_ETH().stake(_msgSender(),value);
    }

    function withdraw(uint256 amount) external {
        liquidityReward_Token_ETH().withdraw(_msgSender(),amount);
    }

    function getReward() external  {
        liquidityReward_Token_ETH().getReward(_msgSender());
    }

    function exit() external {
        liquidityReward_Token_ETH().exit(_msgSender());
    }

}