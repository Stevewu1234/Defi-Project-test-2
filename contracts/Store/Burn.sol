// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";

// Internal References
import "../Interface/IToken.sol";

contract burn is Ownable {
    
    struct BurnEvent {
        uint burntAmount;
        uint burntTime;
    }

    // total burnt amount through the burn contract
    uint public totalBurntAmount;

    // the burn index will only used to get latest burn event status
    uint private burnIndex;

    // the role of executing burn function.
    address internal executor;

    // the burning token address
    address internal burntTokenAddress;

    // record each burn events.
    mapping (uint => BurnEvent) internal burnEvents;

    constructor (address _executor, address _burntTokenAddress) {
        executor = _executor;
        burntTokenAddress = _burntTokenAddress;
        burnIndex = 1;
    }

    /** ========== external view functions =========== */
    
    function latestBurntEvent() external view returns (uint _burntAmount, uint _burntTime) {
        _burntAmount = burnEvents[burnIndex].burntAmount;
        _burntTime = burnEvents[burnIndex].burntTime;
        return (_burntAmount, _burntTime);
    }

    function getBurnEvent(uint _index) external view returns (uint _burntAmount, uint _burntTime) {
        _burntAmount = burnEvents[_index].burntAmount;
        _burntTime = burnEvents[_index].burntTime;
        return (_burntAmount, _burntTime);
    }

    function currentExecutor() external view returns (address) {
        return executor;
    }
    
    /** ========== external mutaive functions =========== */
    function setNewExecutor(address _newExecutor) external onlyOwner {
        require(_newExecutor != address(0), "new executor is not allowed to be null");
        executor = _newExecutor;

        emit updatedExecutor(_newExecutor);
    }

    // executor execute burn() whatever the balances of burning Token amount.
    // but only executor will have the permission to execute burn function.
    function burn() external onlyExecutor {

        uint burntAmount_ = _getBalancesOfBurntToken();

        // execute burn.
        IToken(burntTokenAddress).burn(address(this), burntAmount_);
        burnIndex++;

        // update burntEvent.
        burnEvents[burnIndex].burntAmount = burntAmount_;
        burnEvents[burnIndex].burntTime = block.timestamp;

        // update totalBurntAmount.
        totalBurntAmount = totalBurntAmount + burntAmount_;

        emit burnt(executor, burntAmount);
    }

    /** ========== internal view functions =========== */

    function _getBalancesOfBurntToken() internal view returns (uint) {
        return IToken(burntTokenAddress).balanceOf(address(this));
    }


    /** ========== modifier =========== */

    modifier onlyExecutor {
        require(_msgSender() == executor, "Sorry, You are not executor");
        _;
    }

    /** ========== event =========== */

    updatedExecutor(address indexed newExecutor);
    burnt(address indexed executor, uint indexed burntAmount);

}