// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

abstract contract MetaArtMetaDataUpgradeable is ContextUpgradeable, ERC721URIStorageUpgradeable {

    mapping (address => mapping(string => bool)) private creatorToIPFSPath;

    function metadata_init_unchained() internal initializer {
        __Context_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    /** ========== public view functions ========== */
    function getCreatorUniqueIPFSHashAddress(string memory _path) public view returns (bool) {
        return creatorToIPFSPath[_msgSender()][_path];
    }


    /** ========== internal mutative functions ========== */

    function _setTokenIPFSPath(uint256 tokenId, string memory _path) internal {
        require(bytes(_path).length >= 46, "Invalid IPFS path");
        require(getCreatorUniqueIPFSHashAddress(_path), "NFT has been minted");

        address creator = _msgSender();
        creatorToIPFSPath[creator][_path] = true;

        _setTokenURI(tokenId, _path);

        emit IPFSPathset(creator);
    }


    /** ========== event ========== */

    event IPFSPathset(address indexed creator);

}