//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SwapDataUpgradeable is Initializable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

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

    bytes32 public constant DATA_WRITER = keccak256("WRITE_DATA");
    bytes32 public constant DATA_MIGRATOR = keccak256("DATA_MIGRATOR");

    CountersUpgradeable.Counter private _listingIdTracker;
    CountersUpgradeable.Counter private _offerIdTracker;
    CountersUpgradeable.Counter private _tradeIdTracker;

    mapping(uint256 => SwapListing) private _listings;
    mapping(uint256 => SwapOffer) private _offers;
    mapping(uint256 => Trade) private _trades;

    event SwapListingAdded(SwapListing listing);
    event SwapListingUpdated(SwapListing listing);
    event SwapListingRemoved(uint256 listingId);
    event SwapOfferAdded(SwapOffer offer);
    event SwapOfferUpdated(SwapOffer offer);
    event SwapOfferRemoved(uint256 id);
    event TradeAdded(Trade trade);

    function init(
        address admin,
        address writer
    ) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin); // Admin Wallet address
        _grantRole(DATA_WRITER, writer); // Swap COntract
        _listingIdTracker.increment();
        _offerIdTracker.increment();
        _tradeIdTracker.increment();
    }

    // CRUD Listing
    function addListing(SwapListing memory listing)
        external
        onlyRole(DATA_WRITER)
        returns (bool)
    {
        listing.listingId = _listingIdTracker.current();
        _listings[_listingIdTracker.current()] = listing;
        _listingIdTracker.increment();
        emit SwapListingAdded(listing);
        return true;
    }

    function removeListingById(uint256 id)
        external
        onlyRole(DATA_WRITER)
        returns (bool)
    {
        _listings[id].isCancelled = true;
        emit SwapListingRemoved(id);
        return true;
    }

    function updateListing(SwapListing memory listing)
        external
        onlyRole(DATA_WRITER)
        returns (bool)
    {
        _listings[listing.listingId] = listing;
        emit SwapListingUpdated(listing);
        return true;
    }

    function readListingById(uint256 id)
        external
        view
        returns (SwapListing memory)
    {
        return _listings[id];
    }

    // CRUD Offer
    function addOffer(SwapOffer memory offer)
        external
        onlyRole(DATA_WRITER)
        returns (bool)
    {
        offer.offerId = _offerIdTracker.current();
        _offers[_offerIdTracker.current()] = offer;
        _offerIdTracker.increment();
        emit SwapOfferAdded(offer);
        return true;
    }

    function removeOfferById(uint256 id)
        external
        onlyRole(DATA_WRITER)
        returns (bool)
    {
        _offers[id].isCancelled = true;
        emit SwapOfferRemoved(id);
        return true;
    }

    function updateOffer(SwapOffer memory offer)
        external
        onlyRole(DATA_WRITER)
        returns (bool)
    {
        _offers[offer.offerId] = offer;
        emit SwapOfferUpdated(offer);
        return true;
    }

    function readOfferById(uint256 id)
        external
        view
        returns (SwapOffer memory)
    {
        return _offers[id];
    }

    function addTrade(Trade memory trade)
        external
        onlyRole(DATA_WRITER)
        returns (bool)
    {
        trade.tradeId = _tradeIdTracker.current();
        _trades[_tradeIdTracker.current()] = trade;
        _tradeIdTracker.increment();
        emit TradeAdded(trade);
        return true;
    }

    function readTradeById(uint256 id)
        external
        view
        returns (Trade memory)
    {
        return _trades[id];
    }

    // Bulk reads
    function readAllListings()
        external
        view
        returns (SwapListing[] memory)
    {
        SwapListing[] memory listings = new SwapListing[](
            _listingIdTracker.current() - 1
        );
        for (uint256 i = 0; i < listings.length; i++) {
            listings[i] = _listings[i + 1];
        }
        return listings;
    }

    function readListingsByIndex(
        uint256 start,
        uint256 end
    ) external view returns (SwapListing[] memory list) {
        require(end >= start, 'end should be bigger than start');
        
        uint256 lastIndex = _offerIdTracker.current() - 1;
        uint256 i;
        uint256 to = end;

        if (start > lastIndex) return list;
        if (end > lastIndex) to = lastIndex;

        list = new SwapListing[](to - start + 1);
        for (i = start; i <= to; i++) {
            list[i - start] = _listings[i];
        }
        return list;
    }

    function readAllOffers()
        external
        view
        returns (SwapOffer[] memory)
    {
        SwapOffer[] memory swapOffers = new SwapOffer[](
            _offerIdTracker.current() - 1
        );
        for (uint256 i = 0; i < swapOffers.length; i++) {
            swapOffers[i] = _offers[i + 1];
        }
        return swapOffers;
    }

    function readOffersByIndex(
        uint256 start,
        uint256 end
    ) external view returns (SwapOffer[] memory list) {
        require(end >= start, 'end should be bigger than start');
        
        uint256 lastIndex = _offerIdTracker.current() - 1;
        uint256 i;
        uint256 to = end;

        if (start > lastIndex) return list;
        if (end > lastIndex) to = lastIndex;

        list = new SwapOffer[](to - start + 1);
        for ( i = start; i <= to; i++) {
            list[i - start] = _offers[i];
        }
        return list;
    }

    function readAllTrades()
        external
        view
        returns (Trade[] memory)
    {
        Trade[] memory trades = new Trade[](_tradeIdTracker.current() - 1);
        for (uint256 i = 0; i < trades.length; i++) {
            trades[i] = _trades[i + 1];
        }
        return trades;
    }

    function readTradesByIndex(
        uint256 start,
        uint256 end
    ) external view returns (Trade[] memory list) {
        require(end >= start, 'end should be bigger than start');
        
        uint256 lastIndex = _tradeIdTracker.current() - 1;
        uint256 i;
        uint256 to = end;

        if (start > lastIndex) return list;
        if (end > lastIndex) to = lastIndex;

        list = new Trade[](to - start + 1);
        for (i = start; i <= to; i++) {
            list[i - start] = _trades[i];
        }
    }

    function grantWriterRole(address to) external {
        grantRole(DATA_WRITER, to);
    }
}