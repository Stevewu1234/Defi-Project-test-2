// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/zeppelin/Ownable.sol";

// Libraries
import "../Libraries/SafeMath.sol";

// Internal References
import "../Interface/ILiquidityPool.sol";
import "../Interface/ITradingPool.sol";


contract RewardPool is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    bytes32 private constant CONTRACT_REWARDTOKEN = "RewardToken";
    bytes32 private constant CONTRACT_LIQUIDITYPOOL = "LiquidityPool"; 
    bytes32 private constant CONTRACT_TRADINGPOOL = "TradingPool";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses[0] = CONTRACT_REWARDTOKEN;
        addresses[1] = CONTRACT_LIQUIDITYPOOL;
        addresses[2] = CONTRACT_TRADINGPOOL;
    }

    function rewardToken() internal view returns (IRewardToken) {
        return IRewardToken(requireAndGetAddress(CONTRACT_REWARDTOKEN));
    }

    function liquidityPool() internal view returns (ILiquidityPool) {
        return ILiquidityPool(requireAndGetAddress(CONTRACT_LIQUIDITYPOOL));
    }

    function tradingPool() internal view returns (ITradingPool) {
        return ITradingPool(requireAndGetAddress(CONTRACT_TRADINGPOOL));
    }

    
    uint internal TotalRewardsToDistritute;

    // the index will be pointed to the current rewardpool status,
    // and if there are somthing bad encounterred, update the currentSharesIndex to fallback. 
    uint internal currentSharesIndex;

    // todo need to add a function to make the share records lower than 100%
    
    // save all of the shares and limit the sum of share is lower or equal with 100%. 
    // And the pool name is saved as bytes for accuracy.
    mapping (uint => mapping (bytes32 => uint8)) multiRewardPoolShares;

    mapping (uint => bytes32[]) public poolnames;

    constructor () {
        currentShareIndex = 0;
    }


    /** ========== public view functions ========== */

    function getTotalRewardsToDistribute() public view returns(uint) {
        return TotalRewardsToDistritute = rewardToken().balanceOf(address(this));
    }

    function getLiquidityPoolAmount() public view returns (uint) {
        uint share = multiRewardPoolShares[currentSharesIndex][CONTRACT_LIQUIDITYPOOL];
        return _convertSharestoAmount(share);
    }

    function getTradingPoolAmount() public view returns (uint) { 
        uint share = multiRewardPoolShares[currentSharesIndex][CONTRACT_TRADINGPOOL];
        return _convertSharestoAmount(share);
    }


    /** ========== external mutative onlyOwner functions ========== */

    function updateMultiRewardPoolShares(
        bytes32[] _poolnames,
        uint8[] _poolshares,
        bool updatepoolname
        ) external onlyOwner {
        
        require(_poolnames[].length == _poolshares.length, "the length of two array must be equal");

        _requireMultiSharesSettingCorrectly(_poolshares[]);


        for(uint i = 0; i < _poolnames[].length; i++) {
            multiRewardPoolShares[currentShareIndex][_poolnames[i]] = _poolshares[i];
        }

        // update contract's current rewardpools' status
        if(updatepoolname = true) {
            _updatePoolnames(_poolnames);
            emit rewardpoolnameupdated(_poolnames);
        }
        currentSharesIndex++;
        
        emit multiRewardPoolSharesUpdated(_poolnames[], _poolshares[]);
    }

    function rollbacktoold(uint index) external onlyOwner {
        currentSharesIndex = index;
        emit rollbackToOldAllocation(index);
    }




    /** ========== external view functions ========== */

    // check the current allocation status
    function currentMultiRewardPoolShares() external view returns (uint8[] poolshares) {
        for (uint i = 0; i < _poolnames[currentSharesIndex].length; i++) {
            poolshares[i] = multiRewardPoolShares[currentSharesIndex][_poolnames[currentSharesIndex][i]];
        }
        return poolshares[];
    }

    // check the old allocation status with the index
    function checkOldMultiRewardPoolShares(uint index) external view returns (uint[] poolshares) {
        for(uint i = 0; i<poolnames[index].length; i++){
            poolshares[i] = multiRewardPoolShares[index][poolnames[index][i]];
        }
    }




    /** ========== internal mutative functions ========== */
    function _updatePoolnames(bytes32[] _poolnames) internal {
        for(uint i = 0; i<_poolnames[].length; i++) {
            poolnames[currentSharesIndex][i] = _poolnames[i];
        }
    }


    /** ========== internal view functions ========== */
    function _requireMultiSharesSettingCorrectly(uint8[] _poolshares) internal view {
        for (uint i = 0; i < _poolshares[].length; i++) {
            uint8 totalshares = totalshares.add(_poolshares[i]);
        }
        require(totalshares <= 100, "the totalshares must be set lower or equal with 100(%)");
    }


    // todo must make share accurate
    function _convertSharestoAmount(uint8 share) internal view returns (uint) {
        uint Amount = share.div(100).getTotalRewardsToDistribute();
        return Amount;
    }


    /** ========== modifier ========== */

    /** ========== event ========== */
    event multiRewardPoolSharesUpdated(bytes[] indexed _poolname, uint8[] indexed _poolshares);
    event rewardpoolnameupdated(bytes32[] indexed _poolnames);
    event rollbackToOldAllocation(uint indexed index);
    
}