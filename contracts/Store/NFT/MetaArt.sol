// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetaArtCreatorUpgradeable";
import "./MetaArtMetaDataUpgradeable";
import "./MetaArtMintUpgradeable";
import "@openzeppelin/contract-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract MetaArt is 
        MetaArtCreatorUpgradeable, 
        MetaArtMetaDataUpgradeable, 
        MetaArtMintUpgradeable,
        Initializable,
        ERC721Upgradeable
    {
    
    function metaArt_init(string meory _name, string memory _symbol) external initializer {
        __ERC721_init(_name, _symbol);
        metaMint_init();
        metadata_init();
    }
       



}