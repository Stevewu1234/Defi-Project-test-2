// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./RoleUpgradeable.sol";
import "../NFT/IMetaArt.sol";
import "./SendValueWithFallbackWithdraw.sol";


abstract contract MarketFeeUpgradeable is 
    Initializable, 
    RoleUpgradeable, 
    SendValueWithFallbackWithdraw{
    
    uint256 internal constant BASIS_SHARE = 100;
    uint256 private _primaryBasisShare;
    uint256 private _secondBasisShare;
    uint256 private _secondCreatorBasisShare;

    mapping(address => mapping(uint256 => bool)) private firstSaleCompleted;

    address payable private metaTreasury;

    
    // contract init function
    function metafee_init(
        uint256 _primaryBasisShare_,
        uint256 _secondBasisShare_,
        uint256 _secondCreatorBasisShare_,
        address payable metaTreasury_
    ) internal initializer {
        _primaryBasisShare = _primaryBasisShare_;
        _secondBasisShare = _secondBasisShare_;
        _secondCreatorBasisShare = _secondCreatorBasisShare_;
        metaTreasury = metaTreasury_;
    }

    /** ========== external view functions ========== */

    function getFeeConfig() external view returns (
        uint256 __basisShare,
        uint256 __primaryBasisShare,
        uint256 __secondBasisShare,
        uint256 __secondCreatorBasisShare
    ) {
        return (
            __basisShare = BASIS_SHARE,
            __primaryBasisShare = _primaryBasisShare,
            __secondBasisShare = _secondBasisShare,
            __secondCreatorBasisShare = _secondCreatorBasisShare
        );
    }

    function getFees(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external view returns (
        uint256 metaFee,
        uint256 creatorSecondaryFee,
        uint256 ownerFee
    ) {
        (metaFee, , creatorSecondaryFee, , ownerFee) = _getFees (
            nftContract, tokenId, _getSeller(nftContract, tokenId), price
        );
    }



    /** ========== internal mutative functions ========== */

    function _distributeFee (
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    ) internal returns (
            uint256 metaFee,
            uint256 royalties,
            uint256 ownerFee
        ){
        address payable royaltiesRecipientAddress;
        address payable tokenOwner;

        (metaFee, 
        royaltiesRecipientAddress, 
        royalties, 
        tokenOwner, 
        ownerFee) = _getFees(
            nftContract, 
            tokenId, 
            seller, 
            price);

        // whenever the fees are distributed, make 'firstSaleCompleted' is true.
        // if there is a second-sale happening, the state will not be changed.
        firstSaleCompleted[nftContract][tokenId] = true;

        if(royalties > 0) {
            _sendValueWithFallbackWithdrawWithMediumGasLimit(royaltiesRecipientAddress, royalties);
        }

        _sendValueWithFallbackWithdrawWithLowGasLimit(metaTreasury, metaFee);
        _sendValueWithFallbackWithdrawWithMediumGasLimit(tokenOwner, ownerFee);

        emit auctionFeeDistributed(metaFee, royaltiesRecipientAddress, royalties, tokenOwner, ownerFee);
    }

    // the marketfee update function is only able to be called by admin.
    function _updateMarketFee(
        uint256 primaryBasisShare_,
        uint256 secondBasisShare_,
        uint256 secondCreatorBasisShare_
    ) internal {
        require(metaTreasury == _msgSender(), "only treasury address have the right to modify fee setting");
        require(primaryBasisShare_ < BASIS_SHARE, "fess >= 100%");
        require((secondBasisShare_ + secondCreatorBasisShare_) < BASIS_SHARE, "fess >= 100%");

        _primaryBasisShare = primaryBasisShare_;
        _secondBasisShare = secondBasisShare_;
        _secondCreatorBasisShare = secondCreatorBasisShare_;

        emit marketFeeupdated(
            primaryBasisShare_,
            secondBasisShare_,
            secondCreatorBasisShare_
        );
    }

    /** ========== private view functions ========== */

    function _getFees(
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    ) private view returns (
        uint256 metaFee,
        address payable royaltiesRecipientAddress,
        uint256 royalties,
        address payable tokenOwner,
        uint256 owenrFee
    ) {
        // In generallyl, the payment address is creator, but if there is an assistant address,
        // the assistant address will help complete the operation and receive creator revenue or royalties
        address payable _paymentAddress = IMetaArt(nftContract).getPaymentAddress(tokenId);

        uint256 metaFeeShare;

        // 1. If there is a first-sale happening that 'creator/assistant' is owner of the NFT. 
        // And the owner('tokenOwner') will receive all revenue(only sale revenue) excluding platform fee.
        // 2. If there is a second-sale happening that creator is different from owner.
        // creator will have a certain of revenue called royalties by calculating with '__secondCreatorBasisShare'.
        // platform fee will be adjusted by '__secondBasisShare' and the rest of revenue will be sent to owner(seller).
        if(_getIsPrimary(nftContract, tokenId, seller)) {
            metaFeeShare = _primaryBasisShare;
            tokenOwner = _paymentAddress;
        } else {
            metaFeeShare = _secondBasisShare;
            
            if(_paymentAddress != seller) {
                royaltiesRecipientAddress = _paymentAddress;
                royalties = price * (_secondCreatorBasisShare / BASIS_SHARE);
                tokenOwner = seller;
            }
            
        }

        metaFee = price * (metaFeeShare / BASIS_SHARE);
        // If it is first-sale, there is no royalty.
        owenrFee = price - metaFee - royalties;
    }

    // cause assistant have the authority to mint NFT for creator that the first owner of NFT is different.
    // therefore judging first-sale needs two conditions that 'firstSaleCompleted[nftContract][tokenId]' is false,
    // and seller is creator or assistant.
    function _getIsPrimary(address nftContract, uint256 tokenId, address seller) private view returns (bool) {
        address creator = IMetaArt(nftContract).getTokenIdCreator(tokenId);
        address assistant = IMetaArt(nftContract).getCreatorAssistant(creator);
        bool ifFirstSaleRole = creator == seller || assistant == seller;
        return !firstSaleCompleted[nftContract][tokenId] && ifFirstSaleRole;
    }


    /** ========== event ========== */

    event marketFeeupdated (
        uint256 indexed primaryBasisShare,
        uint256 indexed secondBasisShare,
        uint256 indexed secondCreatorBasisShare
    );

    event auctionFeeDistributed(
        uint256 indexed metaFee,
        address indexed royaltiesRecipientAddress,
        uint256 royalties,
        address indexed tokenOwner,
        uint256 owenrFee
    );

}