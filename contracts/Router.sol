pragma solidity ^0.6.0;

// Inheritance
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./Interface/IRouter.sol";

// Libraries

// Internal References
import "../Interface/IAddressResovler.sol";
import "../Interface/ITokenState.sol";
import "../Interface/IVoteRecord.sol";
import "../Interface/IMerkleDistribution.sol";
import "../Interface/ILiquidityReward_Token_ETH.sol";
import "../SystemController/ISystemStatus.sol";

contract SystemRouter is IRouter, Ownable {

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_RESOLVER = "Resolver";
    bytes32 private constant CONTRACT_TOKENSTATE = "TokenState";
    bytes32 private constant CONTRACT_VOTERECORD = "VoteRecord";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_MERKLEDISTRIBUTION = "MerkleDistribution";
    bytes32 private constant CONTRACT_LIQUDITY_STAKING_TOKEN_ETH = "LiqudityStaking_Token_ETH";
    



    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses[0] = CONTRACT_RESOLVER;
        addresses[1] = CONTRACT_TOKENSTATE;
        addresses[2] = CONTRACT_VOTERECORD;
        addresses[3] = CONTRACT_SYSTEMSTATUS;
        addresses[4] = CONTRACT_MERKLEDISTRIBUTION;
        addresses[5] = CONTRACT_LIQUDITY_STAKING_TOKEN_ETH;
    }

    function resolver() internal view returns (IVoteRecord) {
        return IVoteRecord(requireAndGetAddress(CONTRACT_VOTERECORD));
    }

    function tokenState() internal view returns (ITokenState) {
        return ITokenState(requireAndGetAddress(CONTRACT_TOKENSTATE));
    }

    function voteRecord() internal view returns (IVoteRecord) {
        return IVoteRecord(requireAndGetAddress(CONTRACT_VOTERECORD));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function merkleDistribution() internal view returns (IMerkleDistribution) {
        return IMerkleDistribution(requireAndGetAddress(CONTRACT_MERKLEDISTRIBUTION));
    }

    function liqudityStaking_token_eth() internal view returns (ILiqudityStaking) {
        return ILiqudityStaking_token_eth(requireAndGetAddress(CONTRACT_LIQUDITY_STAKING_TOKEN_ETH));
    }
    

    /** ========== public mutative functions ========== */

    function comeforfun(address from, uint amount) public {

    }


    /** ========== external mutative functions ========== */

    function claim(uint256 index, address account, uint256 _amount, bytes32[] calldata merkleProof) external {
        merkleDistribution().claim(index, account, _amount, merkleProof);
    }

    function claimoflandholder(address _holder) external {
        merkleDistribution().claimoflandholder(_holder);
    }

    function stake(uint256 amount) external {
        liqudityStaking_token_eth().stake(amount);
    }

    function withdraw(uint256 amount) external {
        liqudityStaking_token_eth().withdraw(amount);
    }

    function getReward() external {
        liqudityStaking_token_eth().getReward();
    }

    function exit() external {
        liqudityStaking_token_eth().exit();
    }



    /** ========== public viewable data ========== */


}