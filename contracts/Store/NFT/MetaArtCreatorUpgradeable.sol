// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";


abstract contract MetaArtCreatorUpgradeable is Initializable, ContextUpgradeable  {
    
    mapping(uint256 => address payable) private tokenIdCreator;

    mapping(address => address payable) private creatorAssistant;

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

    // Payment address will be assistant address, if there is a assistant address.
    function getPaymentAddress(uint256 tokenId) public view returns (address payable paymentAddress) {

        address payable creator = getTokenIdCreator(tokenId);
        paymentAddress = getCreatorAssistant(creator);
        if(paymentAddress == address(0)) {
            paymentAddress = creator;
        }
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
    }

    function _deleteTokenIdCreator(uint256 tokenId) internal {
        require(tokenIdCreator[tokenId] == _msgSender(), "only creator have the authority to delete");
        
        delete tokenIdCreator[tokenId];

        emit deletedTokenIdCreator(tokenId, _msgSender());
    }

    function _deleteCreatorAssistant(address creator) internal {
        address assistant = creatorAssistant[creator];
        delete creatorAssistant[creator];

        emit deletedCreatorAssistant(creator, assistant);
    }

    /** ========== event ========== */

    event updatedCreator(uint256 indexed tokenId, address newCreator);
    event updatedAssistant(address indexed creator, address newAssistant);
    event deletedCreatorAssistant(address indexed creator, address deletedAssistant);
    event deletedTokenIdCreator(uint256 indexed tokenId, address creator);
}