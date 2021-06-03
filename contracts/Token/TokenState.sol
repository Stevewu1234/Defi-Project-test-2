// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../Tools/CacheResolver.sol";


// Internal References
import "../Interface/IToken.sol";


/** This contract refer to Synthetix's TokenState Contract. */
contract TokenState is OwnableUpgradeable, CacheResolver {
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;


    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_TOKEN = "Token";

    function tokenstate_init(address _resolver) external initializer {
        _cacheInit(_resolver);
        __Ownable_init();
    }

    function resolverAddressesRequired() public view override returns (bytes32[] memory) {
        bytes32[] memory addresses = new bytes32[](1);
        addresses[0] = CONTRACT_TOKEN;
        return addresses;
    }

    function token() internal view returns (IToken) {
        return IToken(requireAndGetAddress(CONTRACT_TOKEN));
    }


    /** ========== external mutative function ========== */

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
    ) external OnlyInternalContract {
        allowance[tokenOwner][spender] = value;
    }

    /**
     * @notice Set the balance in a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param value The new balance of the given account.
     */
    function setBalanceOf(address account, uint value) external OnlyInternalContract {
        balanceOf[account] = value;
    }

    // Change the associated contract to a new address




    /** ========== modifier ========== */
    
    modifier OnlyInternalContract {
        bool isToken = msg.sender == address(token());
        
        require(isToken, "Only Internal Contracts");
        _;
    }

    /** ========== event ========== */
    event AssociatedContractUpdated(address associatedContract);
}