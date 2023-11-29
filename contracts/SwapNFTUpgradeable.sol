//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/ISwapData.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SwapNFTUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable {
    IERC20Upgradeable private _feeToken;
    ISwapData private dataContract;

    uint256 private totalBips ;
    uint256 public txCharge ;

    event SwapListingCreated(
        address collectionAddress,
        address createdBy,
        uint256 tokenId
    );
    event SwapOfferCreated(
        uint256 listingId,
        address from,
        address offerCollection,
        uint256 tokenId
    );

    event SwapOfferDeclied(
        address declinedBy,
        uint256 offerId,
        uint256 listingId
    );
    event SwapOfferAccepted(
        address acceptedBy,
        uint256 offerId,
        uint256 listingId
    );
    event SwapOfferWithdraw(address owner, uint256 offerId);
    event SwapListingWithdraw(address owner, uint256 listingId);
    event TxChargeChanged(uint256 newTxCharge);
    event TreasuryWalletChanged(address newTreasuryWallet);

    address treasury;

    function init(address admin_, address dataContract_) public initializer {
        __Context_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        dataContract = ISwapData(dataContract_);
        totalBips = 10000;
        totalBips = 10 * 10 ** 18;
        treasury = _msgSender();
    }

    function createListing(
        uint256 tokenId_,
        address nftContract_
    ) external payable {
        IERC721Upgradeable nftContract = IERC721Upgradeable(nftContract_);
        bool isApproved = nftContract.isApprovedForAll(
            _msgSender(),
            address(this)
        );
        require(msg.value == txCharge, "Insufficient tfuel sent for txCharge");
        require(
            isApproved,
            "Approval is required for Swap Contract before listing."
        );
        require(
            nftContract.ownerOf(tokenId_) == _msgSender(),
            "You are not the owner of the NFT"
        );
        ISwapData.SwapListing memory listing;
        listing.listingId = 0;
        listing.tokenAddress = nftContract;
        listing.tokenId = tokenId_;
        listing.tokenOwner = _msgSender();
        listing.transactionChargeBips = 5000;
        listing.isCompleted = false;
        listing.isCancelled = false;
        listing.transactionCharge = txCharge;
        bool isListingCreated = dataContract.addListing(listing);
        require(isListingCreated, "Listing cannot be created");
        emit SwapListingCreated(address(nftContract), _msgSender(), tokenId_);
    }

    function createOffer(
        uint256 tokenId_,
        address nftContract_,
        uint256 listingId_
    ) external {
        IERC721Upgradeable nftContract = IERC721Upgradeable(nftContract_);
        bool isApproved = nftContract.isApprovedForAll(
            _msgSender(),
            address(this)
        );
        require(
            isApproved,
            "Approval is required for Swap Contract before listing."
        );
        require(
            nftContract.ownerOf(tokenId_) == _msgSender(),
            "You are not the owner of the NFT"
        );
        ISwapData.SwapListing memory listing = dataContract.readListingById(
            listingId_
        );
        IERC721Upgradeable listingNftContract = IERC721Upgradeable(listing.tokenAddress);
        require(
            listingNftContract.ownerOf(listing.tokenId) == listing.tokenOwner,
            "Listing Expired"
        );
        ISwapData.SwapOffer memory offer;
        offer.offerTokenAddress = nftContract;
        offer.listingId = listingId_;
        offer.offerTokenId = tokenId_;
        offer.offerTokenOwner = _msgSender();
        offer.listingTokenAddress = listing.tokenAddress;
        offer.listingTokenId = listing.tokenId;
        offer.listingTokenOwner = listing.tokenOwner;
        offer.transactionChargeBips = 5000;
        offer.isCompleted = false;
        offer.isCancelled = false;
        offer.isDeclined = false;
        offer.transactionCharge = txCharge;
        bool isofferCreated = dataContract.addOffer(offer);
        require(isofferCreated, "Offer canot be created.");
        emit SwapOfferCreated(
            listingId_,
            _msgSender(),
            address(nftContract),
            tokenId_
        );
    }

    function declineOffer(uint256 offerId_, uint256 listingId_) external {
        ISwapData.SwapOffer memory offer = dataContract.readOfferById(offerId_);
        ISwapData.SwapListing memory listing = dataContract.readListingById(
            listingId_
        );
        require(
            offer.listingTokenId == listing.tokenId,
            "Inecorrect attempt to decline offer."
        );
        require(
            offer.listingTokenOwner == _msgSender(),
            "You are not authorized to decline offers for this listing."
        );
        offer.isDeclined = true;
        dataContract.updateOffer(offer);
        emit SwapOfferDeclied(_msgSender(), offerId_, listingId_);
    }

    function acceptOffer(uint256 offerId_, uint256 listingId_) external {
        ISwapData.SwapOffer memory offer = dataContract.readOfferById(offerId_);
        ISwapData.SwapListing memory listing = dataContract.readListingById(
            listingId_
        );
        IERC721Upgradeable offerContract = IERC721Upgradeable(offer.offerTokenAddress);
        IERC721Upgradeable listingContract = IERC721Upgradeable(offer.listingTokenAddress);
        require(offer.listingTokenId == listing.tokenId, "Incorrect listing");
        IERC721Upgradeable listingNftContract = IERC721Upgradeable(listing.tokenAddress);
        require(
            listingNftContract.ownerOf(listing.tokenId) == _msgSender(),
            "You are not the owner of this listing"
        );
        require(
            offer.listingTokenId == listing.tokenId,
            "Inecorrect attempt to accept offer."
        );
        require(!listing.isCompleted && !offer.isCompleted, "Invalid request.");
        require(!listing.isCancelled && !offer.isCancelled, "Invalid Request.");
        require(!offer.isDeclined, "Invalid Request");
        bool isOfferTokenApproved = offerContract.isApprovedForAll(
            offer.offerTokenOwner,
            address(this)
        );
        bool isListingTokenApproved = listingContract.isApprovedForAll(
            listing.tokenOwner,
            address(this)
        );
        require(isOfferTokenApproved && isListingTokenApproved, "not approved");

        offerContract.transferFrom(
            offer.offerTokenOwner,
            offer.listingTokenOwner,
            offer.offerTokenId
        );
        listingContract.transferFrom(
            offer.listingTokenOwner,
            offer.offerTokenOwner,
            offer.listingTokenId
        );
        _safeTransferNative(treasury, listing.transactionCharge);
        listing.isCompleted = true;
        offer.isCompleted = true;
        dataContract.updateListing(listing);
        dataContract.updateOffer(offer);
        ISwapData.Trade memory trade;
        trade.listingId = listing.listingId;
        trade.offerId = offer.offerId;
        dataContract.addTrade(trade);
        emit SwapOfferAccepted(_msgSender(), offerId_, listingId_);
    }

    function readAllListings()
        external
        view
        returns (ISwapData.SwapListing[] memory)
    {
        return dataContract.readAllListings();
    }

    function readListingsByIndex(uint256 start, uint256 end) external view returns (ISwapData.SwapListing[] memory){
        return dataContract.readListingsByIndex(start, end);
    }

    function readListingById(
        uint256 id
    ) external view returns (ISwapData.SwapListing memory) {
        return dataContract.readListingById(id);
    }

    function removeListingById(uint256 id) external {
        ISwapData.SwapListing memory listing = dataContract.readListingById(id);
        require(
            _msgSender() == listing.tokenOwner,
            "Only listing creators can remove listings."
        );
        _safeTransferNative(_msgSender(), listing.transactionCharge);
        dataContract.removeListingById(id);
        emit SwapListingWithdraw(_msgSender(), id);
    }

    function readAllOffers()
        external
        view
        returns (ISwapData.SwapOffer[] memory)
    {
        return dataContract.readAllOffers();
    }

    function readOfferById(
        uint256 id
    ) external view returns (ISwapData.SwapOffer memory) {
        return dataContract.readOfferById(id);
    }

    function removeOfferById(uint256 id) external {
        ISwapData.SwapOffer memory offer = dataContract.readOfferById(id);
        require(
            _msgSender() == offer.offerTokenOwner,
            "Only offer creators can remove offers."
        );
        dataContract.removeOfferById(id);
        emit SwapOfferWithdraw(_msgSender(), id);
    }

    function readOffersByIndex(uint256 start, uint256 end) external view returns (ISwapData.SwapOffer[] memory){
        return dataContract.readOffersByIndex(start, end);
    }

    function readAllTrades() external view returns (ISwapData.Trade[] memory) {
        return dataContract.readAllTrades();
    }

    function readTradesByIndex(uint256 start, uint256 end) external view returns (ISwapData.Trade[] memory){
        return dataContract.readTradesByIndex(start, end);
    }

    function readTradeById(
        uint256 id
    ) external view returns (ISwapData.Trade memory) {
        return dataContract.readTradeById(id);
    }

    function setTxCharge(
        uint256 newTxCharge
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        txCharge = newTxCharge;
        emit TxChargeChanged(newTxCharge);
    }

    function setTreasuryWallet(
        address newTreasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = newTreasury;
        emit TreasuryWalletChanged(newTreasury);
    }

    function getTxCharge() external view returns (uint256) {
        return txCharge;
    }

    function _safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }
}