// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AuctionUpgradeable.sol";
import "./MarketFeeUpgradeable.sol";
import "./RoleUpgradeable.sol";
import "./SendValueWithFallbackWithdraw.sol";

contract Market is 
    Initializable,
    RoleUpgradeable, 
    SendValueWithFallbackWithdraw,
    MarketFeeUpgradeable, 
    AuctionUpgradeable
    {


    function market_init(        
        uint256 _primaryBasisShare_,
        uint256 _secondBasisShare_,
        uint256 _secondCreatorBasisShare_,
        address payable metaTreasury_
        ) external {
        auction_init();
        metafee_init(_primaryBasisShare_, _secondBasisShare_, _secondCreatorBasisShare_, metaTreasury_);
        role_init();
    }

    function adminUpdateConfig(
        uint256 primaryBasisShare_,
        uint256 secondBasisShare_,
        uint256 secondCreatorBasisShare_,
        uint256 minIncreasePercent_,
        uint256 duration_,
        uint256 extensionDuration_
    ) external onlyMetaAdmin {
        _updateMarketFee(primaryBasisShare_, secondBasisShare_, secondCreatorBasisShare_);
        _updateAuctionConfig(minIncreasePercent_, duration_, extensionDuration_);
    }


    function adminCancelReserceAuction(uint256 auctionId, string memory reason) external onlyMetaAdmin {
        _adminCancelReserceAuction(auctionId, reason);
    }
}