// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/CacheResolverUpgradeable.sol";
import "./ExternStateToken.sol";

// Internal references
import "../Interface/IVoteRecord.sol";
import "../Interface/ISystemStatus.sol";
import "../Interface/IPortal.sol";


contract Token is OwnableUpgradeable, CacheResolverUpgradeable, ExternStateToken {
    
    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_VOTERECORD = "VoteRecord";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_PORTAL = "Portal";



    function resolverAddressesRequired() public view override returns (bytes32[] memory ) {
        bytes32[] memory addresses = new bytes32[](3);
        addresses[0] = CONTRACT_VOTERECORD;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_PORTAL;
        return addresses;
    }



    function voteRecord() internal view returns (IVoteRecord) {
        return IVoteRecord(requireAndGetAddress(CONTRACT_VOTERECORD));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function portal() internal view returns (IPortal) {
        return IPortal(requireAndGetAddress(CONTRACT_PORTAL));
    }


    /* ========== ERC20 token function ========== */

    /*
     * @description: Replace Constructor function due to Transparent Proxy module.
     * @dev: The initialize function will be called as a calldata while proxy contract deployment.
     * @param {account} accept the initial supplyment of token and be set as a minter to have the authority to mint new supplyment.
     * @param {_totalSupply} the initial supplyment
     */ 
    function token_initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _tokenState,
        address _resolver
        )
        public initializer 
    {
        _externStateTokenInit(
            _name,
            _symbol,
            _owner,
            _tokenState
        );

        _cacheInit(_resolver);

        __Ownable_init();
        minter = _owner;
        emit MinterChanged(address(0), minter);
    }


    /** ========== public mutative functions ========== */

    function transfer(address recipient, uint256 amount) public systemActive returns (bool)  {
        _canTransfer(_msgSender(), amount);
        require(_transfer(_msgSender(), recipient, amount), "fail to transfer");
        voteRecord().moveDelegates(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public systemActive returns (bool)  {
        _canTransfer(sender, amount);
        require(_transfer(_msgSender(), recipient, amount), "fail to transfer");

        uint256 currentAllowance = tokenState.allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        tokenState.setAllowance(sender,recipient,currentAllowance - amount);

        voteRecord().moveDelegates(_msgSender(), recipient, amount);
        
        return true;
    }


    function mint(address to, uint256 value) public systemActive mintfunctionActive {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public systemActive burnfunctionActive {
        _burn(from, value);
        voteRecord().moveDelegates(from, address(0), value);
        
    }

    /** ========== internal view function ========== */
    function _canTransfer(address sender, uint value) internal view returns (bool) {
        uint transferableAmount = portal().getTransferableAmount(sender);
        require(value <= transferableAmount, "can not transfer entered or escrowed");
        return true;
    }


    /** ========== modifier ========== */

    modifier systemActive() {
        systemStatus().requireSystemActive();
        _;
    }

    function _mintfunctionActive() private view returns (bool) {
        bytes32 functionname = "tokenmint";
        bytes32 section_system = "System";
        return systemStatus().requireFunctionActive(functionname,section_system);
    }

    modifier mintfunctionActive() {
        require(_mintfunctionActive(), "mint function has been blocked");
        _;
    }

    function _burnfunctionActive() private view returns (bool) {
        bytes32 functionname = "tokenburn";
        bytes32 section_system = "System";
        return systemStatus().requireFunctionActive(functionname,section_system);
    }

    modifier burnfunctionActive() {
        require(_burnfunctionActive(), "burn function has been blocked");
        _;
    }

    /** ========== event ========== */

}
