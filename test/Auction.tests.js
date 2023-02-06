const ArtToken = artifacts.require('ArtToken')
const ArtNFT = artifacts.require('ArtNFT')
const NFTAuction = artifacts.require('NFTAuction')

require('chai')
.use(require('chai-as-promised'))
.should()

contract('NFTAuction', ([owner, customer, creator, treasury]) => {

    function tokens(number) {
        return web3.utils.toWei(number, 'ether');
    }
 
    let artt, nft

    before(async () => {
        artt = await ArtToken.new()
        nft = await ArtNFT.new('art collection #1', 'AC1', treasury)
        auctionHouse = await NFTAuction.new(treasury, 10, artt.address, nft.address)

        // Transfer all 100 ARTT tokens to Auction House
        await artt.transfer(auctionHouse.address, '1000000000000000000000000', {from: owner})
        // Create NFT
        await nft.mintNFT(creator, 'test NFT token', '0x74657374204e465420746f6b656e', '10', '0x3732DF56aC266869318744A6EA82E9A7e8Db5100', true)
    })

    describe('ArtToken Deployment', async () => {
        it('matches name successfully', async () => {
            const name = await artt.name()
            assert.equal(name, 'Art Token')
        })
    })

    describe('AuctionHouse balance of ArtToken', async () => {
        it('contract has tokens', async () => {
            let auctionHouseBalance = await artt.balanceOf(auctionHouse.address)
            assert.equal(auctionHouseBalance.toString(), '1000000000000000000000000')
        })
    })

    describe('AuctionHouse balance of ArtToken', async () => {
        it('contract has tokens', async () => {
            let ownerBalance = await artt.balanceOf(owner)
            assert.equal(ownerBalance.toString(), '0')
        })
    })

})