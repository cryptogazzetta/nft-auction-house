// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract ArtNFT is ERC721URIStorage, AccessControl, ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(uint256 => bytes32) private _tokenHash;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address internal immutable _projectTreasury;


    /// @notice Deploys the contract
    /// @param name of the collection
    /// @param symbol of the collection
    /// @param projectTreasury address of the project treasury
    constructor(
        string memory name,
        string memory symbol,
        address projectTreasury
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _projectTreasury = projectTreasury;
    }


    /// @notice Checks for interface suppport
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice mints new NFT to the collection
    /// @param author address of the author
    /// @param nftURI Uniform Resource Identifier of the NFT
    /// @param hash of the NFT info
    /// @param royaltyValue royalty share from future sales
    /// @param auctionHouse address of the auction smart contract
    /// @param setApprove bool is the auction house allowed to transact the NFT?
    /// @return id of minted NFT
    function mint(
        address author,
        string memory nftURI,
        bytes32 hash,
        uint96 royaltyValue,
        address auctionHouse,
        bool setApprove
    ) internal returns (uint256 id) {
        uint256 _id = _tokenIds.current();
        _tokenIds.increment();

        _mint(author, id);
        _setTokenURI(id, nftURI);
        _tokenHash[id] = hash;
        _setTokenRoyalty(id, author, royaltyValue);

        if (setApprove) {
            _approve(auctionHouse, _id);
        }

        return id;
    }


    /// @notice mints new NFT by calling mint function
    /// @param author address of the author
    /// @param nftURI Uniform Resource Identifier of the NFT
    /// @param hash of the NFT info
    /// @param royaltyValue royalty share from future sales
    /// @param auctionHouse address of the auction smart contract
    /// @param setApprove bool is the auction house allowed to transact the NFT?
    /// @return mint calls the mint function
    function mintNFT(
        address author,
        string memory nftURI,
        bytes32 hash,
        uint96 royaltyValue,
        address auctionHouse,
        bool setApprove
    ) external virtual onlyRole(MINTER_ROLE) returns (uint256) {
        return mint(author, nftURI, hash, royaltyValue, auctionHouse, setApprove);
    }


    /// @notice informs the hash of given token's info
    /// @param tokenId id of the token
    /// @return hash of the given token
    function tokenHash(uint256 tokenId) public view returns (bytes32) {
        return _tokenHash[tokenId];
    }


    

}