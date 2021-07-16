// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./MarketFeeUpgradeable.sol";
import "./MigrationSignature.sol";

abstract contract AuctionUpgradeable is 
    Initializable, 
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    MarketFeeUpgradeable,
    MigrationSignature

    {
    
    uint256 public nextAuctionId;

    struct ReserveAuction {
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address payable bidder;
        uint256 currentPrice;
    }

    mapping (address => mapping(uint256 => uint256)) private tokenToAuctionId;
    mapping (uint256 => ReserveAuction) private reserveAuctions;

    uint256 private _minIncreasePercent;
    uint256 private _duration;
    uint256 private _extensionDuration;

    uint256 private constant MAX_DURATION = 1000 days;


    function auction_init() internal initializer {
        nextAuctionId = 1;
        _duration = 24 hours;
        _extensionDuration = 15 minutes;
        _minIncreasePercent = 10;  // 10% of BASIS_SHARES
    }


    /** ========== public view functions ========== */

    function getAuctionInformation(uint256 auctionId) public view returns (ReserveAuction memory) {
        return reserveAuctions[auctionId];
    }

    function getTokenToAuctionID(address nftContract, uint256 tokenId) public view returns (uint256) {
        return tokenToAuctionId[nftContract][tokenId];
    }

    function getAuctionConfiguration() public view returns (
        uint256 duration_,
        uint256 extensionDuration_,
        uint256 minIncreasePercent_
    ) {
        duration_ = _duration;
        extensionDuration_ = _extensionDuration;
        minIncreasePercent_ = _minIncreasePercent;
    }
    
    /** ========== external mutative functions ========== */


    // 1. only NFT owner have the rights to create auction entry despite the primary-sale or second-sale
    // 2. when auction is created, it will not countdown until first bid.
    // 3. cause seller(owner) of NFT is not linked to NFT creator or second-saler directly,
    // therefore seller have the authority to migrate the auction to another user who will be new seller.
    // but of course the creator(or assistant if there is one) will have a certain of the royalties after NFT sold.
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 reservePrice
    ) external nonReentrant {

        require(reservePrice > 0, "the reserve price must not be 0");
        require(tokenToAuctionId[nftContract][tokenId] == 0, "sorry, the auction of the NFT has been in progress");
        require(IERC721Upgradeable().ownerOf(tokenId) == _msgSender(), "sorry, you could not sell NFT which you do not have");

        uint256 auctionId = _getNextAuctionId();
        tokenToAuctionId[nftContract][tokenId] = auctionId;

        reserveAuctions[auctionId] = ReserveAuction( {
            nftContract: nftContract,
            tokenId: tokenId,
            seller: _msgSender(),
            duration: _duration,
            extensionDuration: _extensionDuration,
            endTime: 0,  // endTime is only known once the first bid
            bidder: address(0), // bidder will be recorded once the placebid() calling
            currentPrice: reservePrice
        });
        
        // once the auction of the NFT has been created, the NFT will be transferred from caller address
        IERC721Upgradeable(nftContract).transferFrom(_msgSender(), address(this), tokenId);

        emit auctionCreated(
            nftContract,
            tokenId,
            _msgSender(),
            auctionId,
            _duration,
            _extensionDuration,
            reservePrice
        );
    }

    // the seller of the auction have the authority to update reserve price before first bid.
    function updateAuction(uint256 auctionId, uint256 reservePrice) external {
        ReserveAuction storage reserveAuction = reserveAuctions[auctionId];
        require(reservePrice > 0, "the reserve price must not be 0");
        require(reserveAuction.seller == _msgSender(), "the auction is not yours");
        require(reserveAuction.endTime == 0, "the auction has been in progress");

        reserveAuction.currentPrice = reservePrice;

        emit auctionUpdated(auctionId, reservePrice);
    }

    // the seller of the auction have the authority to cancel the auction before first bid.
    function cancelAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory reserveAuction = reserveAuctions[auctionId];
        require(reserveAuction.seller == _msgSender(), "the auction is not yours");
        require(reserveAuction.endTime == 0, "the auction has been in progress");

        delete reserveAuctions[auctionId];
        delete tokenToAuctionId[reserveAuction.nftContract][reserveAuction.tokenId];

        IERC721Upgradeable(reserveAuction.nftContract).transfer(reserveAuction.seller, reserveAuction.tokenId);

        emit auctionCancelled(auctionId);
    }

    // user who like the selling NFT could place bid.
    // 1. If it is first bid of the selling NFT, that will trigger countdown of the auction
    // and the default duration is 24 hour which is referring to foundation setting.
    // placed price must higher than reserve price which seller set.
    // 2. If it is second bid of the selling NFT, there are following setting.
    //   1. The same address is not allowed to bid twice.
    //   2. Placed price must higher than _getMinBidAmount().
    //   3. The auction duration is not over.
    //   4. As soon as new bidder is accepted, the privous bid fee will be refund to original bidder.
    // P.S. There is extension duration which allow user place a bid after auction duration is over.
    //      During the extension duration, new bid will update the auction end time until there is no one bid.
    function placeBid(uint256 auctionId) external payable nonReentrant {
        ReserveAuction storage reserveAuction = reserveAuctions[auctionId];
        require(reserveAuction.currentPrice > 0, "auction is invalid");

        if(reserveAuction.endTime == 0 && reserveAuction.bidder == address(0)) {
            require(msg.value >= reserveAuction.currentPrice, "bid must be at least the reserve price");

            reserveAuction.currentPrice = msg.value;
            reserveAuction.bidder = _msgSender();
            reserveAuction.endTime = block.timestamp + reserveAuction.duration;
        } else {
            require(reserveAuction.endTime >= block.timestamp, "sorry, the auction is over");
            require(reserveAuction.bidder != address(0) && reserveAuction.bidder != _msgSender(), "the bidder is not allowed bid twice");
            require(msg.value > _getMinBidAmount(reserveAuction.currentPrice), "bid amount is too low");

            uint256 originalAmount = reserveAuction.currentPrice;
            address payable originalBidder = reserveAuction.bidder;
            
            reserveAuction.currentPrice = msg.value;
            reserveAuction.currentPrice = _msgSender();

            // If there is no one bid in extensionDuration after endTime, the last bidder will get the NFT
            if(reserveAuction.endTime - block.timestamp < reserveAuction.extensionDuration) {
                reserveAuction.endTime = block.timestamp + reserveAuction.extensionDuration;
            }

            _sendValueWithFallbackWithdrawWithLowGasLimit(originalBidder, originalAmount);
        }

        emit auctionBidPlaced(auctionId, _msgSender(), msg.value, reserveAuction.endTime);
    }

    // Anyone has the authority to finalize the closing auction.
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction storage reserveAuction = reserveAuctions[auctionId];

        require(reserveAuction.endTime > 0 && reserveAuction.bidder != address(0), "the auction is still waitting to bid");
        require(reserveAuction.endTime - block.timestamp > reserveAuction.extensionDuration, "the auction is still in the last extension duration"); 

        delete reserveAuctions[auctionId];
        delete tokenToAuctionId[reserveAuction.nftContract][reserveAuction.tokenId];

        IERC721Upgradeable(reserveAuction.nftContract).transfer(reserveAuction.bidder, reserveAuction.tokenId);

        (uint256 metaFee, 
        uint256 royalties, 
        uint256 ownerFee) = _distributeFee(
            reserveAuction.nftContract, 
            reserveAuction.tokenId, 
            reserveAuction.seller, 
            reserveAuction.currentPrice);

        emit auctionFinalized(metaFee, royalties, ownerFee);
    }

    // even though the auction has started, admin can still cancel reserve auction but need reasonable reason.
    function _adminCancelReserceAuction(uint256 auctionId, string memory reason) internal  {
        ReserveAuction memory reserveAuction = reserveAuctions[auctionId];
        require(bytes(reason).length > 0, "cancellation reason is necessary");
        require(reserveAuction.currentPrice > 0, "the auction not found");
        
        delete reserveAuctions[auctionId];
        delete tokenToAuctionId[reserveAuction.nftContract][reserveAuction.tokenId];

        IERC721Upgradeable(reserveAuction.nftContract).transfer(reserveAuction.seller, reserveAuction.tokenId);

        if(reserveAuction.bidder != address(0)) {
            _sendValueWithFallbackWithdrawWithLowGasLimit(reserveAuction.bidder, reserveAuction.currentPrice);
        }

        emit auctionCancelledbyAdmin(auctionId, reason);
    }


    // Auction migration will transfer the revenue of NFT selling as well.
    function auctionMigration(
        uint256[] calldata auctionIds,
        address originalAddress,
        address payable newAddress,
        bytes calldata signature) external {
            // original address must sign the migration operation through meta site.
            _requireAuthorizedMigration(originalAddress, newAddress, signature);

            for(uint256  i = 0; i < auctionIds[].length; i++) {
                uint256 auctionId = auctionIds[i];
                ReserveAuction storage reserveAuction = reserveAuctions[auctionId];

                require(reserveAuction.seller == originalAddress, "The migrating auction is not created by original address");
                reserveAuction.seller = newAddress;
                
                emit reserveAuctionMigrated(auctionId, originalAddress, newAddress);
            }
            
    }

    /** ========== internal mutative functions ========== */
    function _getNextAuctionId() internal returns (uint256) {
        return nextAuctionId++;
    }

    function _updateAuctionConfig(
        uint256 minIncreasePercent_,
        uint256 duration_,
        uint256 extensionDuration_
    ) internal {
        require(duration_ < MAX_DURATION, "new value must be lower than 'MAX_DURATION'");
        require(duration_ > extensionDuration_, "auction duration must higher than extension duration");

        _minIncreasePercent = minIncreasePercent_;
        _duration = duration_;
        _extensionDuration = extensionDuration_;

        emit auctionConfigUpdated(minIncreasePercent_, duration_, extensionDuration_);
    }

    /** ========== internal view functions ========== */

    function _getMinBidAmount(uint256 currentPrice) internal view returns (uint256) {
        uint256 minIncreament = currentPrice * (_minIncreasePercent / BASIS_SHARE);
        
        return minIncreament + currentPrice;
    }

    /** ========== event ========== */
    event auctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 indexed auctionId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice
    );

    event auctionUpdated(
        uint256 indexed auctionId, 
        uint256 reservePrice
    );

    event auctionCancelled(uint256 indexed auctionId);

    event auctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 price,
        uint256 endTime
    );

    event auctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 metafee,
        uint256 creatorfee,
        uint256 ownerfee
    );

    event auctionCancelledbyAdmin(
        uint256 indexed auctionId, 
        string reason
    );

    event reserveAuctionMigrated(
        uint256 indexed auctionId, 
        address indexed originalAddress, 
        address newAddress
    );

    event auctionConfigUpdated(
        uint256 indexed minIncreasePercent_,
        uint256 indexed duration_,
        uint256 indexed extensionDuration_
    );
}