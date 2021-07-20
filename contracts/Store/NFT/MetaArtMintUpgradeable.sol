// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./MetaArtCreatorUpgradeable.sol";
import "./MetaArtMetaDataUpgradeable.sol";


abstract contract MetaArtMintUpgradeable is 
    Initializable, 
    ContextUpgradeable, 
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    MetaArtCreatorUpgradeable,
    MetaArtMetaDataUpgradeable
    {
    
    uint256 private nextTokenId;

    function metaMint_init(string memory _name, string memory _symbol) internal initializer {
        nextTokenId = 1;
        __Context_init_unchained();
        creator_init_unchained();
        __ERC721_init(_name, _symbol);
    } 

    /** ========== public view functions ========== */

    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    /** ========== external mutative functions ========== */

    function mint(string memory tokenIPFSPath) external returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        address operator = _msgSender();
        address creator = getAssistantCreator(operator) != address(0)? getAssistantCreator(operator): _msgSender();
        
        _mint(operator, tokenId);
        _setTokenIdCreator(tokenId, payable(creator));
        _setTokenIPFSPath(tokenId, tokenIPFSPath);

        emit ArtWorkMinted(creator, tokenId, tokenIPFSPath);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
        _deleteTokenIdCreator(tokenId);
        _deleteCreatorAssistant(_msgSender());
    }


    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /** ========== event ========== */

    event ArtWorkMinted(address indexed creator, uint256 indexed tokenId, string indexed IPFSPath);
}