const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT Marketplace", function () {
  let signers;

  let market, nft, score;
  beforeEach(async function () {
    signers = await ethers.getSigners();
    const NFTMarket = await ethers.getContractFactory("NFTMarket");
    market = await NFTMarket.deploy();
    await market.deployed();

    const Score = await ethers.getContractFactory("Score");
    score = await Score.deploy(market.address);
    await score.deployed();

    const NFT = await ethers.getContractFactory("NFT");
    nft = await NFT.deploy(market.address);
    await nft.deployed();

    market.setScoreContract(score.address);
  });

  it("List NFT", async function () {
    [minter] = signers;

    await nft.connect(minter).mint("https://tokenURI", 5);
    expect(await nft.ownerOf(1)).eq(minter.address); // minter should be  the owner

    await market
      .connect(minter)
      .listToken(nft.address, 1, ethers.utils.parseEther("5.0"));

    expect(await nft.ownerOf(1)).eq(market.address); // ownership of the NFT transferred to the marketplace
    const listing = await market.getListingById(1);
    expect(listing.price.toString()).eq(ethers.utils.parseEther("5.0")); // listing price eq to 5 ETH
    expect(listing.onSale).eq(true); //  `onSale` should be true

    expect((await score.getScoreByAddress(minter.address)).toString()).eq(
      ethers.utils.parseEther("1")
    ); // score of the minter should be 1 ETH
  });
  it("Buy NFT", async function () {
    [minter, buyer] = signers;

    await nft.connect(minter).mint("https://tokenURI", 5);

    await market
      .connect(minter)
      .listToken(nft.address, 1, ethers.utils.parseEther("5.0"));

    await market
      .connect(buyer)
      .buyToken(nft.address, 1, { value: ethers.utils.parseEther("5.0") });

    expect(await nft.ownerOf(1)).eq(buyer.address);

    const listing = await market.getListingById(1);
    expect(listing.onSale).eq(false);
    expect(listing.sold).eq(true);
    expect(listing.owner).eq(buyer.address);
  });
  it("Cancel listing", async function () {
    [minter] = signers;

    await nft.connect(minter).mint("https://tokenURI", 5);

    await market
      .connect(minter)
      .listToken(nft.address, 1, ethers.utils.parseEther("5.0"));

    expect(await nft.ownerOf(1)).eq(market.address);
    await market.connect(minter).cancelSale(nft.address, 1);
    expect(await nft.ownerOf(1)).eq(minter.address);
  });
});