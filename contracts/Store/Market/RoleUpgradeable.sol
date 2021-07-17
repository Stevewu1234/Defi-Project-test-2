// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../NFT/IMetaArt.sol";

abstract contract RoleUpgradeable is Initializable, AccessControlUpgradeable {

    bytes32 constant private OPERATOR = "operator";

    function role_init(address admin) internal initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /** ========== external mutative functions ========== */

    function updateAdmin(address _newadmin) external {
        require(_newadmin != address(0), "new address must not be null");
        grantRole(DEFAULT_ADMIN_ROLE, _newadmin);
    }

    function updateOperator(address _newoperator) external {
        require(_newoperator != address(0), "new address must not be null");
        grantRole(OPERATOR, _newoperator);
    }

    function revokeAdmin(address revokingAdmin) external {
        revokeRole(DEFAULT_ADMIN_ROLE, revokingAdmin);
    }

    function revokeOperator(address revokingOperator) external {
        revokeRole(OPERATOR, revokingOperator);
    }

    /** ========== internal view functions ========== */

    function _getSeller(
        address nftContract, 
        uint256 tokenId
        ) internal view returns (address payable seller){

        return seller = payable(IMetaArt(nftContract).ownerOf(tokenId));
    } 


    /** ========== modifier ========== */

    modifier onlyMetaAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only admin can call");
        _;
    }

    modifier onlyMetaOperator() {
        require(hasRole(OPERATOR, _msgSender()), "only operator can call");
        _;
    }



}