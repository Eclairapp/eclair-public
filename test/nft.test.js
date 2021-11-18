const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT", function () {
  it("Mint NFTs", async function () {
    const [minter] = await ethers.getSigners();
    const NFTMarket = await ethers.getContractFactory("NFTMarket");
    const market = await NFTMarket.deploy();
    await market.deployed();

    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy(market.address);
    await nft.deployed();

    await nft.connect(minter).mint("https://tokenURI", 5);

    expect(await nft.balanceOf(minter.address)).eq(1);
    expect(await nft.ownerOf(1)).eq(minter.address);

    await nft.connect(minter).mint("https://tokenURI", 5);
    expect(await nft.balanceOf(minter.address)).eq(2);
    expect(await nft.ownerOf(2)).eq(minter.address);
  });

  it("Burn NFTs", async function () {
    const [minter] = await ethers.getSigners();
    const NFTMarket = await ethers.getContractFactory("NFTMarket");
    const market = await NFTMarket.deploy();
    await market.deployed();

    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy(market.address);
    await nft.deployed();

    await nft.connect(minter).mint("https://tokenURI", 5);

    expect(await nft.balanceOf(minter.address)).eq(1);

    await nft.connect(minter).burn(1);
    expect(await nft.balanceOf(minter.address)).eq(0);
  });

  it("Transfer NFTs", async function () {
    const [minter, holder] = await ethers.getSigners();
    const NFTMarket = await ethers.getContractFactory("NFTMarket");
    const market = await NFTMarket.deploy();
    await market.deployed();

    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy(market.address);
    await nft.deployed();

    await nft.connect(minter).mint("https://tokenURI", 5);

    expect(await nft.balanceOf(minter.address)).eq(1);

    await nft.connect(minter).transferFrom(minter.address, holder.address, 1);

    expect(await nft.balanceOf(minter.address)).eq(0);
    expect(await nft.balanceOf(holder.address)).eq(1);
  });
});