// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author Christian Gazzetta
/// @title Simple auction for NFTs


// "https://github.com/belane/just-nft/blob/main/contracts/NFTAuction.sol"
// Main changes: 
// Original code had a max price defined at start as "endingPrice"
// Original code had a "cancelAuctionWhenPaused" function
// Change Eth to ART as payment token

// Future improvements:
/// deposits to the contract to allow multiple bids without many transactions

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ArtToken.sol";
import "./ArtNFT.sol";

contract NFTAuction is Ownable, Pausable, ReentrancyGuard {
    
    /// @notice Events
    event AuctionCreated(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        // Could use uint96?
        uint256 duration
    );
    event AuctionBid(uint256 tokenId, uint256 bid, address bidder);
    event AuctionFinish(uint256 tokenId, uint256 price, address winner);
    event AuctionCancelled(uint256 tokenId);
    event Deposit(address depositor, address receiver, uint256 amount);

    /// @notice Global variables
    ArtToken public artt;
    ArtNFT public nft;
    uint256 private immutable _auctionFee;
    address private immutable _projectTreasury;
    mapping(uint256 => Auction) private _tokenIdAuction;

    mapping(address => uint256) private _bidDeposits;

    /// @notice Auction data structure
    struct Auction {
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        address seller;
        uint64 startedAt;
        address lastBidder;
        uint256 lastBid;
    }


    /**
    * @notice Deploys the contract,
    * defines the address of the project treasury and the auction fee,
    * sets ArtToken and artNFT contracts as artt and nft
    */
    constructor(address projectTreasury, uint256 auctionFee, ArtToken _artt, ArtNFT _nft) {
        artt = _artt;
        nft = _nft;
        transferOwnership(msg.sender);
        _projectTreasury = projectTreasury;
        _auctionFee = auctionFee;
    }


    /// @notice Gets address of the treasury
    function getTreasury() public view returns(address) {
        return _projectTreasury;
    }

    /// @notice Checks whether the auction already exists in the record
    function isAuction(uint256 tokenId) public view returns (bool) {
        Auction memory _auction = _tokenIdAuction[tokenId];
        return (_auction.startedAt > 0);
    }


    /// @notice Checks whether the auction is currently live
    function isAuctionOpen(uint256 tokenId) public view returns (bool) {
        Auction memory _auction = _tokenIdAuction[tokenId];
        return (_auction.startedAt > 0 && _auction.startedAt + _auction.duration > block.timestamp);
    }


    /// @notice Checks whether the auction has finished
    /// @param tokenId of the token being sold
    /// @return _isFinished bool: is auction finished?
    function isAuctionFinish(uint256 tokenId) public view returns (bool _isFinished) {
        // Defines auction by tokenId
        Auction memory _auction = _tokenIdAuction[tokenId];
        // Checks if auction has started and finished
        _isFinished = _auction.startedAt > 0 && _auction.startedAt + _auction.duration <= block.timestamp;
        return _isFinished;
    }


    /// @notice Pauses the auction house
    function pause() public onlyOwner {
        _pause();
    }


    /// @notice Resumes the auction house
    function unpause() public onlyOwner {
        _unpause();
    }


    /// @notice Creates an auction by filling an auction struct with given data
    /// @dev If approval is not set yet, front-end should call approve function of the NFT collection contract
    /// @param tokenId id of the token to be sold
    /// @param startingPrice minimum price
    /// @param duration duration of the auction in seconds
    function createAuction(uint256 tokenId, uint256 startingPrice, uint256 duration) public whenNotPaused {
        // Check Overflow
        require(startingPrice == uint256(uint128(startingPrice)));
        require(duration == uint256(uint64(duration)));
        require(duration >= 1 minutes);

        // Checks whether an auction of this NFT has already started
        require(_tokenIdAuction[tokenId].startedAt == 0, "Running Auction");
        
        // Defines owner of the NFT using ERC721.ownerOf(tokenId)
        address nftOwner = nft.ownerOf(tokenId);
        // Checks whether the msg sender is the owner of the NFT
        require(msg.sender == nftOwner, "Only the owner of this NFT can start auction");

        // Escrow NFT
        // Check for allowance
        nft.transferFrom(nftOwner, address(this), tokenId);
        
        // Create struct with given data
        Auction memory _auction = Auction(
            uint128(startingPrice),
            0,
            uint64(duration),
            nftOwner,
            uint64(block.timestamp),
            address(0),
            0
        );
        _tokenIdAuction[tokenId] = _auction;

        emit AuctionCreated(
            uint256(tokenId),
            uint256(_auction.startingPrice),
            0,
            uint256(_auction.duration)
        );
    }


    /// @notice Registers new bid
    /// @param tokenId id of the wanted token
    /// @param bidValue value of the new bid
    function bid(uint256 tokenId, uint256 bidValue) external whenNotPaused nonReentrant {
        Auction memory _auction = _tokenIdAuction[tokenId];
        // 1. Checks status of auction and bid value
        require(isAuctionOpen(tokenId), "Auction not open");
        require(bidValue > _auction.startingPrice, "Bid bellow min price");
        require(bidValue > _auction.lastBid, "Bid bellow last bid");
        require(bidValue <= artt.balanceOf(msg.sender), "Not enough balance of ARTT");
        // Transfer bid to the contract
        artt.transferFrom(msg.sender, address(this), bidValue);

        // Defines previous last bid and previous last bidder
        address previousLastBidder = _tokenIdAuction[tokenId].lastBidder;
        uint256 previousLastBid = _tokenIdAuction[tokenId].lastBid;
        // If auction has had another bid, refund last bidder
        if(previousLastBidder != address(0) && previousLastBid != 0) {
            artt.transferFrom(address(this), previousLastBidder, previousLastBid);
        }

        // Redefine last bid and last bidder
        _tokenIdAuction[tokenId].lastBidder = msg.sender;
        _tokenIdAuction[tokenId].lastBid = bidValue;
        // emit event
        emit AuctionBid(tokenId, bidValue, msg.sender);
    }


    /// @notice Stops the auction, sends back the NFT and refunds last bid
    /// @param tokenId id of the token being auctioned
    function cancelAuction(uint256 tokenId) external nonReentrant {
        Auction memory _auction = _tokenIdAuction[tokenId];
        address nftOwner = nft.ownerOf(tokenId);
        // Checks status of the auction and access rights of the msg sender
        require(isAuctionOpen(tokenId), "Auction not open");
        require(msg.sender == owner() || msg.sender == nftOwner, "Not Authorized");

        // Refunds last bid
        if (_auction.lastBid > 0) {
            artt.transfer(_auction.lastBidder, _auction.lastBid);
        }
        // Sends back NFT
        nft.transferFrom(address(this), _auction.seller, tokenId);

        delete _tokenIdAuction[tokenId];
        emit AuctionCancelled(tokenId);
    }

    /// @notice Closes the auction and excludes its struct from auctions' mapping
    /// @param tokenId id of the token being auctioned
    function finishAuction(uint256 tokenId) external whenNotPaused nonReentrant {
        Auction memory _auction = _tokenIdAuction[tokenId];
        require(isAuctionFinish(tokenId), "Auction not finished");

        // If auction had no bids, send NFT back to its owner
        if (_auction.lastBid == 0) {
            nft.transferFrom(address(this), _auction.seller, tokenId);
            emit AuctionFinish(tokenId, 0, _auction.seller);
        // If starting price was reached, transfer the NFT to the last bidder
        } else {
            nft.transferFrom(
                address(this),
                _auction.lastBidder,
                tokenId
            );
            
            // Splits the gain between seller proceeds and treasury fee
            uint256 treasuryFee = (_auction.lastBid * _auctionFee) / 10000;
            uint256 sellerProceeds = _auction.lastBid - treasuryFee;
            artt.transfer(_projectTreasury, treasuryFee);
            artt.transfer(_auction.seller, sellerProceeds);
            
            // emits event to the blockchain
            emit AuctionFinish(tokenId, _auction.lastBid, _auction.lastBidder);
        }
        // Delete auction from dataset.
        // Should we include a dataset of past auctions??
        delete _tokenIdAuction[tokenId];
    }


    /// @notice Informs the auction info of the given token
    /// @param tokenId id of the token being auctioned
    /// @return seller
    /// @return startingPrice
    /// @return endingPrice
    /// @return duration
    /// @return startedAt time of start
    /// @return lastBid best bid
    /// @return lastBidder bidder of the best bid
    function getAuction(uint256 tokenId)
        external
        view
        returns (
            address seller,
            uint256 startingPrice,
            uint256 endingPrice,
            uint256 duration,
            uint256 startedAt,
            uint256 lastBid,
            address lastBidder
        )
    {
        Auction memory _auction = _tokenIdAuction[tokenId];
        require(isAuction(tokenId), "Not Auction");
        return (
            _auction.seller,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            _auction.startedAt,
            _auction.lastBid,
            _auction.lastBidder
        );
    }


    /// @notice Informs the auction starting price of the given token
    /// @param tokenId id of the token being auctioned
    /// @return startingPrice
    function getAuctionStartingPrice(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        Auction memory _auction = _tokenIdAuction[tokenId];
        require(isAuction(tokenId), "Not Auction");
        uint256 auctionStartingPrice = _auction.startingPrice;
        return (auctionStartingPrice);
    }


    /// @notice informs the best bid of auction of the given token
    /// @param tokenId id of the token being auctioned
    /// @return lastBid best bid value
    function getLastBid(uint256 tokenId) external view returns (uint256) {
        require(isAuction(tokenId), "Not Auction");
        return _tokenIdAuction[tokenId].lastBid;
    }
}
