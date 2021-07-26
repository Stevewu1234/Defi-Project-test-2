// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

abstract contract MetaArtMetaDataUpgradeable is ContextUpgradeable, ERC721URIStorageUpgradeable {

    mapping (address => mapping(string => bool)) private creatorToIPFSPath;

    string private baseURI;

    function metadata_init(string memory baseURI_) internal initializer {
        __Context_init_unchained();
        __ERC721URIStorage_init_unchained();
        _setBaseURI(baseURI_);
    }

    /** ========== public view functions ========== */
    function getCreatorUniqueIPFSHashAddress(string memory _path) public view returns (bool) {
        return creatorToIPFSPath[_msgSender()][_path];
    }

    function metaBaseURI() public view returns (string memory) {
        return baseURI;     
    }

    /** ========== internal mutative functions ========== */

    // The IPFS path should be the CID + file.extension, e.g: [IPFSPath]/metadata.json
    // Therefore the length of '_path' may be longer than 46.
    function _setTokenIPFSPath(uint256 tokenId, string memory _path) internal {
        require(bytes(_path).length >= 46, "Invalid IPFS path");
        require(getCreatorUniqueIPFSHashAddress(_path), "NFT has been minted");

        address creator = _msgSender();
        creatorToIPFSPath[creator][_path] = true;

        _setTokenURI(tokenId, _path);

        emit IPFSPathset(creator, _path);
    }

    function _deleteTokenIdIPFS(uint256 tokenId) internal {
        delete creatorToIPFSPath[_msgSender()][tokenId];

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory baseURI_) internal {
        baseURI = baseURI_;

        emit baseURIUpdated(baseURI_);
    }


    /** ========== event ========== */

    event IPFSPathset(address indexed creator, string path);
    event baseURIUpdated(string baseURI);

}