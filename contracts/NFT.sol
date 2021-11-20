// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/IERC2981.sol";

contract NFT is ERC721URIStorage, IERC2981 {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIds;
    address public market;

    struct RoyaltyInfo {
        address reciever;
        uint256 percent;
    }

    mapping(uint256 => RoyaltyInfo) royalties;

    constructor(address marketAddress) ERC721("Art Token", "ART") {
        market = marketAddress;
    }

    function mint(string memory _tokenURI, uint256 royalty)
        public
        returns (uint256)
    {
        require(royalty >= 0 && royalty < 100);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        royalties[newItemId] = RoyaltyInfo(msg.sender, royalty);

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        setApprovalForAll(market, true);
        return newItemId;
    }

    function burn(uint256 _tokenId) external {
        address owner = ownerOf(_tokenId);
        address operator = msg.sender;
        require(owner == operator);
        _burn(_tokenId);
    }

    // Check if token exists
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory rInfo = royalties[_tokenId];
        if (rInfo.reciever == address(0)) return (address(0), 0);

        uint256 amount = (_salePrice * rInfo.percent) / 100;
        return (rInfo.reciever, amount);
    }

    function giveMarketApproval() public {
        // to be called if the marketplace doesn't have approval for the user.
        // can be checked using `isApprovedForAll`

        // gives market approval for all tokens of msg.sender
        setApprovalForAll(market, true);
    }
}
