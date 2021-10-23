// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IMarket {
    struct Royalities {
        // % of sale value that goes to the _previous_ owner of the nft
        uint256 prevOwner;
        // % of sale value that goes to the original creator of the nft
        uint256 creator;
        // % of sale value that goes to the seller (current owner) of the nft
        uint256 owner;
    }
    event royaltiesupdated(uint256 indexed tokenId, Royalities royalities);

    function royalitiesForToken(uint256 tokenId)
        external
        view
        returns (Royalities memory);

    function isValidRoyality(Royalities calldata royalities)
        external
        pure
        returns (bool);

    function setRoyalities(uint256 tokenId, Royalities calldata royalities)
        external;
}
