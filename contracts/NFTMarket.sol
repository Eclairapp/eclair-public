// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IScore.sol";
import "./interface/INFT.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;

    address payable public owner;
    address payable public score; // Score contract

    uint256 public buyingPoints = 100; // percentage of price to be alloted as the score

    uint256 public listingFee = 30; // 3% -> (30 / 1000)

    Counters.Counter private _currentId;
    struct Listing {
        uint256 listingId;
        address nft;
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool sold;
        bool onSale;
    }

    mapping(uint256 => Listing) public saleListings;
    mapping(address => mapping(uint256 => uint256)) royalties;

    event TokenListed(
        uint256 indexed listingId,
        address nft,
        uint256 tokenId,
        address payable indexed seller,
        uint256 price
    );

    event TokenSold(
        uint256 indexed listingId,
        address nft,
        uint256 tokenId,
        address payable owner,
        address payable indexed seller,
        uint256 price
    );

    event SaleCancelled(
        uint256 indexed listingId,
        address nft,
        uint256 tokenId
    );

    constructor() {
        owner = payable(msg.sender);
    }

    // Set the address of score contract.
    // This needs to be done before any other actions on the contract.
    function setScoreContract(address scoreAddress) public onlyOwner {
        require(msg.sender == owner);
        score = payable(scoreAddress);
    }

    function listToken(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant {
        require(INFT(nftContract).ownerOf(tokenId) == msg.sender, "NOT_OWNER");

        _currentId.increment();
        uint256 current = _currentId.current();
        address payable seller = payable(msg.sender);
        saleListings[current] = Listing(
            current,
            nftContract,
            tokenId,
            payable(address(0)),
            seller,
            price,
            false,
            true
        );
        INFT(nftContract).transferFrom(msg.sender, address(this), tokenId);
        IScore(score).updateScore(msg.sender, 1 ether);

        emit TokenListed(current, nftContract, tokenId, seller, price);
    }

    function buyToken(address nftContract, uint256 listingId)
        external
        payable
        nonReentrant
        tokenOnSale(listingId)
    {
        uint256 price = saleListings[listingId].price;
        uint256 tokenId = saleListings[listingId].tokenId;
        require(msg.value == price, "VALUE_NEQ_PRICE"); // check if amount sent is equal to the price of NFT

        INFT(nftContract).transferFrom(address(this), msg.sender, tokenId); // send NFT to buyer

        saleListings[listingId].owner = payable(msg.sender);
        saleListings[listingId].sold = true;
        saleListings[listingId].onSale = false;

        uint256 listingFeeAmount = (price * listingFee) / 1000;
        (address reciever, uint256 royalty) = INFT(nftContract).royaltyInfo(
            tokenId,
            price
        );

        // handle royalties
        if (reciever == address(0)) {
            saleListings[listingId].seller.transfer(
                msg.value - listingFeeAmount
            );
        } else {
            payable(reciever).transfer(royalty);
            saleListings[listingId].seller.transfer(
                msg.value - listingFeeAmount - royalty
            );
        }

        // send the protocol fee
        payable(owner).transfer(listingFeeAmount / 2);
        payable(score).transfer(listingFeeAmount / 2);

        // Update scores for buyer and seller
        IScore(score).updateScore(msg.sender, (price * buyingPoints) / 1000);
        IScore(score).updateScore(
            saleListings[listingId].seller,
            (price * buyingPoints) / 1000
        );

        emit TokenSold(
            listingId,
            saleListings[listingId].nft,
            tokenId,
            owner,
            saleListings[listingId].seller,
            price
        );
    }

    function cancelSale(address nftContract, uint256 listingId)
        external
        nonReentrant
        tokenOnSale(listingId)
    {
        require(msg.sender == saleListings[listingId].seller, "NOT_SELLER");

        saleListings[listingId].onSale = false;

        address payable seller = saleListings[listingId].seller;
        uint256 tokenId = saleListings[listingId].tokenId;
        INFT(nftContract).transferFrom(address(this), seller, tokenId);

        emit SaleCancelled(listingId, saleListings[listingId].nft, tokenId);
    }

    function getListingById(uint256 listingId)
        public
        view
        returns (Listing memory)
    {
        return saleListings[listingId];
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier tokenOnSale(uint256 listingId) {
        require(saleListings[listingId].onSale == true, "NOT_ON_SALE");
        _;
    }
}
