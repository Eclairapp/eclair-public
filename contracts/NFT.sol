// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/** 
CHECKLIST
[*] Mint
[*] Burn
[*] Transfer (Automatically inherited)
[*] Approvals (Automatically inherited)

[*] Testing
*/

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    address market;

    constructor(address marketAddress) ERC721("Art Token", "ART") {
        market = marketAddress;
    }

    function mint(string memory _tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

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
}
