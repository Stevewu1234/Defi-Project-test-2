pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/** This contract refer to Synthetix's TokenState Contract. But  */
contract TokenState is Ownable {
    mapping(address => uint) public balanceOf;
    mapping(addrss => mapping(address => uint)) public allowance;
    address public associatedContract;

    constructor(address _associatedContract) public {
        require(_associatedContract != address(0), "you must set the associated Contract");
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /** ========== external function ========== */

    /**
     * @notice Set ERC20 allowance.
     * @dev Only the associated contract may call this.
     * @param tokenOwner The authorising party.
     * @param spender The authorised party.
     * @param value The total value the authorised party may spend on the
     * authorising party's behalf.
     */
    function setAllowance(
        address tokenOwner,
        address spender,
        uint value
    ) external onlyAssociatedContract {
        allowance[tokenOwner][spender] = value;
    }

    /**
     * @notice Set the balance in a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param value The new balance of the given account.
     */
    function setBalanceOf(address account, uint value) external onlyAssociatedContract {
        balanceOf[account] = value;
    }

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /** ========== modifier ========== */
    modifier OnlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /** ========== event ========== */
    event AssociatedContractUpdated(address associatedContract);
}