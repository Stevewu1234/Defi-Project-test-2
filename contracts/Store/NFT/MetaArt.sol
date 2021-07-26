// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetaArtCreatorUpgradeable.sol";
import "./MetaArtMetaDataUpgradeable.sol";
import "./MetaArtMintUpgradeable.sol";
import "./MigrationSignature.sol";

contract MetaArt is 
        Initializable,
        MetaArtCreatorUpgradeable,
        MetaArtMetaDataUpgradeable,
        MetaArtMintUpgradeable,
        MigrationSignature
    {
    
    function metaArt_init(string memory _name, string memory _symbol, string memory baseURI_) external initializer {
        creator_init_unchained();
        metadata_init(baseURI_);
        metaMint_init(_name, _symbol);
    }

    /** ========== external mutative functions ========== */
    
    function updateBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /** ========== override functions ========== */

    function _burn(uint256 tokenId) internal virtual override(MetaArtMintUpgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(MetaArtMintUpgradeable, ERC721URIStorageUpgradeable)returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function _baseURI() internal view override(MetaArtMintUpgradeable, MetaArtMetaDataUpgradeable) returns (string memory) {
        return _baseURI();
    }

    /** ========== migration functions ========== */

    // only migrate creator, and even transfer NFT to new creator if original creator is holding the NFT.
    // assistant address will not be transferred even though the original creator do not have any NFTs.
    // therefore the new creators would able to add new assistant basing on their needs.
    function creatorRoleMigrateWithNFTs(
        uint256[] calldata tokenIds,
        address originalAddress,
        address payable newCreator,
        bytes calldata signature
    ) public {
        _requireAuthorizedMigration(originalAddress, newCreator, signature);
        
        for(uint256 i; i < tokenIds.length; i++ ) {
            uint256 currentTokenId = tokenIds[i];
            require(getTokenIdCreator(currentTokenId) == payable(originalAddress), "sorry, caller is not creator of migrating NFT");

            if(ownerOf(currentTokenId) == originalAddress) {
                _transfer(originalAddress,newCreator, currentTokenId);
                _setTokenIdCreator(currentTokenId, newCreator);
                
            } else {
                _setTokenIdCreator(currentTokenId, newCreator);
            }
        }
        emit CreatorMigrated(originalAddress, newCreator, tokenIds);
    }

    event CreatorMigrated(address indexed originalAddress, address newCreator, uint256[] tokenIds);

}