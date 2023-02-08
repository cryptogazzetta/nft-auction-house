const { assert } = require('chai')

const ArtToken = artifacts.require('ArtToken')
const ArtNFT = artifacts.require('ArtNFT')
const NFTAuction = artifacts.require('NFTAuction')

require('chai')
.use(require('chai-as-promised'))
.should()

contract('NFTAuction', ([owner, customer, creator, treasury]) => {
    // Turns into 18 decimals
    function tokens(number) {
        return web3.utils.toWei(number, 'ether');
    }

    function timeout(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
 
    let artt, nft

    before(async () => {
        artt = await ArtToken.new()
        nft = await ArtNFT.new('art collection #1', 'AC1', treasury)
        auctionHouse = await NFTAuction.new(treasury, 10, artt.address, nft.address)


        // Transfer 5K tokens (50% of owner balance) to auction house address
        await artt.transfer(auctionHouse.address, tokens('5000'), {from: owner})
        // Transfer 1K tokens (10% of owner balance) to customer
        await artt.transfer(customer, tokens('1000'), {from: owner})
        // Create NFT
        await nft.mintNFT(creator, 'test NFT token', '0x74657374204e465420746f6b656e', '0', auctionHouse.address, true)
        // Start auction for the new NFT
        await auctionHouse.createAuction(0, tokens('100'), '10', {from: creator})
    })


    /**
    * Testing the ArtToken Contract
    */
    describe('ArtToken Deployment', async () => {
        it('matches name successfully', async () => {
            let name = await artt.name()
            assert.equal(name, 'Art Token')
        })
    })

    describe('Owner address of ArtToken', async () => {
        it('owner has no tokens', async () => {
            let ownerAddress = await artt.owner()
            assert.equal(ownerAddress, owner)
        })
    })

    describe('Treasury balance of ArtToken', async () => {
        it('treasury has no tokens', async () => {
            let treasuryBalance = await artt.balanceOf(treasury)
            assert.equal(treasuryBalance, '0')
        })
    })

    describe('Owner balance of ArtToken', async () => {
        it('owner has 4K tokens', async () => {
            let ownerBalance = await artt.balanceOf(owner)
            assert.equal(ownerBalance.toString(), tokens('4000'))
        })
    })

    describe('Customer balance of ArtToken', async () => {
        it('customer has 1K tokens', async () => {
            let ownerBalance = await artt.balanceOf(customer)
            assert.equal(ownerBalance.toString(), tokens('1000'))
        })
    })

    describe('Creator balance of ArtToken', async () => {
        it('Creator has no tokens', async () => {
            let ownerBalance = await artt.balanceOf(creator)
            assert.equal(ownerBalance.toString(), '0')
        })
    })

    describe('Auction House Contract balance of ArtToken', async () => {
        it('Contract has 5K tokens', async () => {
            let ownerBalance = await artt.balanceOf(auctionHouse.address)
            assert.equal(ownerBalance.toString(), tokens('5000'))
        })
    })

    describe('Is ARTT paused', async () => {
        it('ARTT transactions are paused', async () => {
            // Pause ARTT transfers
            await artt.pause({from: owner})
            let isPaused = await artt.isPaused()
            assert.equal(isPaused, true)
        })
    })


    /**
    * Testing the ArtNFT Contract
    */
    describe('ArtNFT Deployment', async () => {
        it('matches name successfully', async () => {
            let name = await nft.name()
            assert.equal(name, 'art collection #1')
        })
    })
    
    describe('First ArtNFT', async () => {
        it('matches URI successfully', async () => {
            let uri = await nft.tokenURI(0)
            assert.equal(uri, 'test NFT token')
        })
    })


    /**
    * Testing the NFTAuction Contract
    */
   describe('NFTAuction Deployment', async() => {
    it('matches treasury address', async () => {
        let treasuryAddress = await auctionHouse.getTreasury()
        assert.equal(treasuryAddress, treasury)
    })
   })

   describe('NFTAuction start auction', async() => {
    it('is first NFT being offered', async () => {
        let isAuction = await auctionHouse.isAuction(0)
        assert.equal(isAuction, true)
    })
   })

   describe('Auction status', async() => {
    it('is NFT auction open', async () => {
        let isAuctionOpen = await auctionHouse.isAuctionOpen(0)
        assert.equal(isAuctionOpen, true)
    })
   })

   describe('Starting Price', async() => {
    it('is starting price 100', async () => {
        let startingPrice = await auctionHouse.getAuctionStartingPrice(0)
        assert.equal(startingPrice, tokens('100'))
    })
   })

   describe('NFT Owner', async() => {
    it('is NFT held by auction house during auction', async () => {
        let nftOwner = await nft.ownerOf(0)
        assert.equal(nftOwner, auctionHouse.address)
    })
   })

   describe('Last Bid', async() => {
    it('Last Bid equals 103 ARTT', async () => {
        // Customer sets allowance makes a bid
        await artt.approve(auctionHouse.address, tokens('103'), {from: customer})
        await auctionHouse.bid(0, tokens('103'), {from: customer})
        
        let lastBid = await auctionHouse.getLastBid(0)
        assert.equal(lastBid, tokens('103'))
    })
   })

   describe('Auction status, NFT owner and customer balance after end of auction', async() => {
    it('is NFT auction closed, is customer holding NFT and has customer paid for NFT', async () => {
        
        await timeout(10000);
        await auctionHouse.finishAuction(0)
        let isAuctionOpen = await auctionHouse.isAuctionOpen(0)
        let nftOwner = await nft.ownerOf(0)
        let customerBalance = await artt.balanceOf(customer)

        assert.equal(isAuctionOpen, false)
        assert.equal(nftOwner, customer)
        assert.equal(customerBalance, tokens('897'))
    })
   })

   describe('Auction status and NFT owner after cancel', async() => {
    it('is NFT auction closed and is creator holding NFT again', async () => {
        await auctionHouse.createAuction(0, tokens('100'), 3, {from: customer})
        await auctionHouse.cancelAuction(0)
        let isAuctionOpen = await auctionHouse.isAuctionOpen(0)
        let nftOwner = await nft.ownerOf(0)

        assert.equal(isAuctionOpen, false)
        assert.equal(nftOwner, customer)
    })
   })

})
