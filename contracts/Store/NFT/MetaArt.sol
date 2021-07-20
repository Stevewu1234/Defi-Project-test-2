// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetaArtCreatorUpgradeable.sol";
import "./MetaArtMetaDataUpgradeable.sol";
import "./MetaArtMintUpgradeable.sol";

contract MetaArt is 
        Initializable,
        ERC721Upgradeable,
        MetaArtCreatorUpgradeable,
        MetaArtMetaDataUpgradeable,
        MetaArtMintUpgradeable
    {
    
    function metaArt_init(string memory _name, string memory _symbol) external initializer {
        creator_init_unchained();
        metadata_init_unchained();
        metaMint_init(_name, _symbol);
    }
    

    function setCreatorAssistant(address payable newCreatorAssistantAddress) external {
        address creator = _msgSender();
        _setCreatorAssistant(creator, newCreatorAssistantAddress);
        _setAssistantCreator(newCreatorAssistantAddress, payable(creator));
    }

    function deleteCreatorAssistant(address payable deletingCreatorAssistant) external {
        address creator = _msgSender();
        require(getCreatorAssistant(creator) == deletingCreatorAssistant, "deleting assistant is not your assistant");
        _deleteCreatorAssistant(creator);
    }
    
    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable, MetaArtMintUpgradeable) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable, MetaArtMintUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

}