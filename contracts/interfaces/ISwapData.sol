//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ISwapData {
    struct SwapListing {
        uint256 listingId;
        IERC721Upgradeable tokenAddress;
        uint256 tokenId;
        address tokenOwner;
        uint256 transactionChargeBips;
        bool isCompleted;
        bool isCancelled;
        uint256 transactionCharge;
    }

    struct SwapOffer {
        uint256 offerId;
        uint256 listingId;
        IERC721Upgradeable offerTokenAddress;
        uint256 offerTokenId;
        address offerTokenOwner;
        IERC721Upgradeable listingTokenAddress;
        uint256 listingTokenId;
        address listingTokenOwner;
        uint256 transactionChargeBips;
        bool isCompleted;
        bool isCancelled;
        bool isDeclined;
        uint256 transactionCharge;
    }

    struct Trade {
        uint256 tradeId;
        uint256 listingId;
        uint256 offerId;
    }

    event SwapListingAdded(SwapListing listing);
    event SwapListingUpdated(SwapListing listing);
    event SwapListingRemoved(uint256 listingId);
    event SwapOfferAdded(SwapOffer offer);
    event SwapOfferUpdated(SwapOffer offer);
    event SwapOfferRemoved(uint256 id);
    event TradeAdded(Trade trade);

    function addListing(SwapListing memory listing) external returns (bool);

    function removeListingById(uint256 id) external;

    function updateListing(SwapListing memory listing) external;

    function readListingById(uint256 id)
        external
        view
        returns (SwapListing memory);

    function addOffer(SwapOffer memory offer) external returns (bool);

    function removeOfferById(uint256 id) external;

    function updateOffer(SwapOffer memory offer) external;

    function readOfferById(uint256 id) external view returns (SwapOffer memory);

    function addTrade(Trade memory trade) external;

    function readTradeById(uint256 id) external view returns (Trade memory);

    function readAllListings() external view returns (SwapListing[] memory);

    function readAllOffers() external view returns (SwapOffer[] memory);

    function readAllTrades() external view returns (Trade[] memory);
    function readListingsByIndex(
        uint256 start,
        uint256 end
    ) external view returns (SwapListing[] memory);

    function readOffersByIndex(
        uint256 start,
        uint256 end
    ) external view returns (SwapOffer[] memory);
    function readTradesByIndex(
        uint256 start,
        uint256 end
    ) external view returns (Trade[] memory);
}
