// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contract-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contract-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contract-upgradeable/token/ERC721/ERC721Upgradeable.sol";


abstract contract MetaArtCreatorUpgradeable is ContextUpgradeable, Initializable, ERC721Upgradeable {

    struct Ownership {
        address payable creatorAddress,
        address payable assistantAddress
    }
    
    // mapping (uint256 => address payable) private tokenIdCreator;

    mapping (uint256 => Ownership) private tokenOwnerships;



    function creator_init() internal initializer {
        __Context_init_unchained();
    }

    /** ========== public view functions ========== */

    function getTokenIdCreator(uint256 tokenId) public view returns (address payable) {
        return tokenOwnerships[tokenId].creatorAddress;
    }

    function getCreatorAssistant(uint256 tokenId) public view returns (address payable) {
        return tokenOwnerships[tokenId].assistantAddress;
    }

    function getTokenOwnerShip(uint tokenId) public view returns (address payable creator, address payable assistant) {
        creator = tokenOwnerships[tokenId].creatorAddress;
        assistant = tokenOwnerships[tokenId].assistantAddress;
    }

    function getPaymentAddress(uint256 tokenId) public view returns (address payable paymentAddress) {

        paymentAddress = getCreatorAssistant(tokenId);
        if(paymentAddress == address(0)) {
            paymentAddress = getTokenIdCreator(tokenId);
        }
    }

    function isCreatorEqualOwner(uint256 tokenId) public view returns (bool) {
        return tokenIdCreator[tokenId] == ownerOf[tokenId];
    }

    function hasCreatorAssistant(uint256 tokenId) public view returns (bool) {
        return creatorsAssistant[tokenIdCreator[tokenId]] != address(0);
    }


    /** ========== internal mutative functions ========== */

    function _setTokenIdCreator(uint256 tokenId, address creator) internal {
        require(!_exists(tokenId), "ERC721: token already minted");

        tokenIdCreator[tokenId] = creator;

        emit updatedCreator(tokenId, creator);
    }

    function _setTokenIdCreatorsAssistant(uint256 tokenId, address payable newTokenIdCreatorsAssistantAddress) internal {
        require(newTokenIdCreatorsAssistantAddress != address(0), "new address must not be null");
        address creator = tokenIdCreator[tokenId];

        creatorsAssistant[creator] = newTokenIdCreatorsAssistantAddress;

        emit updatedAssistant(tokenId, newTokenIdCreatorsAssistantAddress);
    }

    function _deleteCreatorAssistant(address creator) internal {
        require(creator == _msgSender(), "only creators can delete their assistant addresses");
        delete creatorsAssistant[creator];

        emit deletedCreator(tokenId, creator);
    }

    /** ========== modifier ========== */

    // modifier onlyCreatorandOwner(uint256 tokenId) {
    //     require(tokenIdCreator[tokenId] == _msgSender(), "caller is not creator");
    //     require(ownerOf(tokenId) == _msgSender(), "call is not owner of this NFT");
    //     _;
    // }

    /** ========== event ========== */

    event updatedCreator(uint256 indexed tokenId, address newCreator);
    event updatedAssistant(uint256 indexed tokenId, address newAssistant);
    event deletedCreator(uint256 indexed tokenId, address deletedCreator);
}