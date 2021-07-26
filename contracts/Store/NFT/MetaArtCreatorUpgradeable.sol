// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./MigrationSignature.sol";


abstract contract MetaArtCreatorUpgradeable is Initializable, ContextUpgradeable, MigrationSignature  {
    

    // creator will only have the following differences from owner.
    //   1. creator will receive royalties from NFT selling.
    //   2. only when creators own the NFT which they created, the burn() can be called.
    mapping(uint256 => address payable) private tokenIdCreator;

    // creators could authority an assistant address to implement partial functions 
    // and the assistant address would able to be an alternative address of creators as well.
    // if a creator have an assistant, the results of following functions will be a little different.
    //   1. assistant -> mint(). Assistants will receive the new NFT but the creator role will be keep to their creators.
    //   2. assistant -> finalizeReserveAuction(). the royalties will be sent to the payment address of sold token.
    //   And the payment address will be assistant address if there is one.
    mapping(address => address payable) private creatorAssistant;

    // check if the caller is an assistant address of one of creators. 
    mapping(address => address payable) private assistantCreator;

    function creator_init_unchained() internal initializer {
        __Context_init_unchained();
    }

    /** ========== public view functions ========== */

    function getTokenIdCreator(uint256 tokenId) public view returns (address payable) {
        return tokenIdCreator[tokenId];
    }

    function getCreatorAssistant(address creator) public view returns (address payable) {
        return creatorAssistant[creator];
    }

    function getAssistantCreator(address assistant) public view returns (address payable) {
        return assistantCreator[assistant];
    }

    // royalties will be sent to assistant address if the creator of the sold NFT have set an assistant.
    function getPaymentAddress(uint256 tokenId) public view returns (address payable paymentAddress) {

        address payable creator = getTokenIdCreator(tokenId);
        paymentAddress = getCreatorAssistant(creator);
        if(paymentAddress == address(0)) {
            paymentAddress = creator;
        }
    }

    /** ========== external mutative functions ========== */

    function setCreatorAssistant(address payable newCreatorAssistantAddress) external {
        address creator = _msgSender();
        _setCreatorAssistant(creator, newCreatorAssistantAddress);
        _setAssistantCreator(newCreatorAssistantAddress, payable(creator));
    }

    function deleteCreatorAssistant(address payable deletingCreatorAssistant) external {
        address creator = _msgSender();
        require(getCreatorAssistant(creator) == deletingCreatorAssistant, "deleting assistant is not your assistant");
        _deleteCreatorAssistant(creator);
        _deleteAssistantCreator(deletingCreatorAssistant);
    }

    /** ========== internal mutative functions ========== */

    function _setTokenIdCreator(uint256 tokenId, address payable creator) internal {

        tokenIdCreator[tokenId] = creator;

        emit updatedCreator(tokenId, creator);
    }

    function _setCreatorAssistant(address creator, address payable newCreatorsAssistantAddress) internal {
        require(newCreatorsAssistantAddress != address(0), "new address must not be null");

        creatorAssistant[creator] = newCreatorsAssistantAddress;

        emit updatedAssistant(creator, newCreatorsAssistantAddress);
    }

    function _setAssistantCreator(address assistant, address payable assistantCreatorAddress) internal {
        require(creatorAssistant[assistantCreatorAddress] == assistant, "creators must set their assistant in advance");

        assistantCreator[assistant] = assistantCreatorAddress;

        emit updatedAssistantCreator(assistant, assistantCreatorAddress);
    }

    function _deleteTokenIdCreator(uint256 tokenId) internal {
        require(tokenIdCreator[tokenId] == _msgSender(), "only creator have the authority to delete");
        
        delete tokenIdCreator[tokenId];

        emit deletedTokenIdCreator(tokenId, _msgSender());
    }

    function _deleteCreatorAssistant(address creator) internal {
        address assistant = creatorAssistant[creator];

        if(assistant != address(0)) {
            delete creatorAssistant[creator];
        }

        emit deletedCreatorAssistant(creator, assistant);
    }

    function _deleteAssistantCreator(address assistant) internal {
        address creator  = assistantCreator[assistant];

        if(creator != address(0)) {
            delete assistantCreator[assistant];
        }

        emit deletedAssistantCreator(assistant, creator);
    }

    /** ========== event ========== */

    event updatedCreator(uint256 indexed tokenId, address newCreator);
    event updatedAssistant(address indexed creator, address newAssistant);
    event updatedAssistantCreator(address indexed assistant, address assistantCreator);

    event deletedCreatorAssistant(address indexed creator, address deletedAssistant);
    event deletedTokenIdCreator(uint256 indexed tokenId, address creator);
    event deletedAssistantCreator(address indexed assistant, address deletedCreator);
}