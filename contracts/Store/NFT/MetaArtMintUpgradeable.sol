// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contract-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contract-upgradeable/proxy/Initializable.sol";
import "./MetaArtCreatorUpgradeable.sol";


abstract contract MetaArtMintUpgradeable is 
    ContextUpgradeable, 
    Initializable, 
    MetaArtCreatorUpgradeable{
    
    uint256 private nextTokenId;

    function metaMint_init() internal initializer {
        nextTokenId = 1;
        __Context_init_unchained();
    } 

    /** ========== public view functions ========== */

    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    /** ========== external mutative functions ========== */

    function mint(string memory tokenIPFSPath) external returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        address creator = _msgSender();
        _mint(creator, tokenId);
        _setTokenIdCreator(tokenId, creator);
        _setTokenIPFSPath(tokenIPFSPath);

        emit ArtWorkMinted(creator, tokenId, tokenIPFSPath);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
        _deleteTokenIdCreator(tokenId, _msgSender());
    }

    /** ========== event ========== */

    event ArtWorkMinted(address indexed creator, uint256 indexed tokenId, string indexed IPFSPath);
}