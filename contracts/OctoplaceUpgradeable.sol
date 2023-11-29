// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IOwnable {
    function owner() external view  returns (address);
}

contract OctoplaceMarketUpgradeable is Initializable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _itemIds; // Id for each individual item
    CountersUpgradeable.Counter private _itemsSold; // Number of items sold

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @notice The super admin address / owner
    address public superAdmin;
    address public pendingSuperAdmin;

    /// @notice The admin address
    address public admin;

    address public feeAddress;

    mapping(address => address) private contractOwners;

    uint256 salesFeeBasisPoints ;
    bool public listingIsActive ;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 highestOffer;
        address bidder;
        string category;
        uint256 price;
        bool isSold;
    }

    struct Creator {
        address creator;
        uint256 feeBasisPoints;
    }

    //    mapping that keeps all items ever placed on the marketplace
    mapping(uint256 => MarketItem) private idToMarketItem;

    //    mapping NFT address to creators address
    mapping(address => Creator) private AddressToCreatorFeeItem;

    function init(address feeAddress_) public initializer() {

        __ReentrancyGuard_init();
        superAdmin = payable(msg.sender);
        feeAddress = payable(feeAddress_);
        salesFeeBasisPoints= 400;
        listingIsActive = true;
    }

    fallback() external payable {}

    receive() external payable {}

    // Event called when a new Item is created
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 tokenId,
        address indexed seller,
        address owner,
        string category,
        uint256 price,
        bool isSold
    );

    // Event called when a new Item is updated
    event MarketItemUpdated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 tokenId,
        address indexed seller,
        address owner,
        string category,
        uint256 price,
        bool isSold
    );

    // Event called when an Item is sold
    event MarketItemSale(
        uint256 indexed itemId,
        address nftContract,
        uint256 tokenId,
        address indexed seller,
        address indexed owner,
        string category,
        uint256 price,
        bool isSold
    );

    // Event when someone places a offer
    event OfferPlaced(
        uint256 indexed itemId,
        address nftContract,
        uint256 tokenId,
        address indexed seller,
        uint256 highestOffer,
        address indexed bidder,
        string category,
        uint256 price
    );

    // Event when someone cancels a offer
    event OfferCanceled(
        uint256 indexed itemId,
        address nftContract,
        uint256 tokenId,
        address indexed seller,
        address indexed previousBidder,
        uint256 price
    );

    // Event called TFuel is spit into creator fee, opentheta fee and payment to seller
    event FeeSplit(
        uint256 userPayout,
        address indexed userAddress,
        uint256 feePayout,
        address indexed feeAddress,
        uint256 creatorPayout,
        address indexed creatorAddress
    );

    // Event called when creator base fee points are changed or set
    event CreatorFeeChanged(
        address indexed nftContract,
        address indexed creatorAddress,
        uint256 BasisFeePoints
    );
    // Event called when platform fee changes
    event PlatformFeeChanged(uint256 indexed BasisFeePoints);
    

    /**
     * @notice modifiers
     */
    modifier onlySuperAdmin() {
        require(
            msg.sender == superAdmin,
            "only the super admin can perform this action"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin || msg.sender == superAdmin,
            "only the admin can perform this action"
        );
        _;
    }
    
    function retrieveMoney(uint256 amount) external onlySuperAdmin {
        require(
            amount <= address(this).balance,
            "You can not withdraw more money than there is"
        );
        payable(feeAddress).transfer(amount);
    }

    function setSalesFeeBasisPoints(
        uint256 feeBasisPoints
    ) external onlySuperAdmin {
        require(feeBasisPoints <= 1000, "Sales Fee cant be higher than 10%");
        salesFeeBasisPoints = feeBasisPoints;
        emit PlatformFeeChanged(salesFeeBasisPoints);
    }

    /**
     * @notice Change the fee address
     * @param feeAddress_ The address of the new fee address
     */
    function setFeeAddress(address feeAddress_) external onlySuperAdmin {
        feeAddress = feeAddress_;
    }

    /**
     * @notice Change the admin address
     * @param pendingSuperAdmin_ The address of the new super admin
     */
    function setPendingSuperAdmin(address pendingSuperAdmin_) onlySuperAdmin external {
        require(pendingSuperAdmin_ != address(0), "Zero address cannot be made a super admin");
	    pendingSuperAdmin = pendingSuperAdmin_;
	}

    /**
     * @notice approve the admin address change
     */
    function approvePendingSuperAdmin() onlySuperAdmin external {
        require(pendingSuperAdmin != address(0), "Zero address cannot be made a super admin");
	    superAdmin = pendingSuperAdmin;
	    pendingSuperAdmin = address(0);
	}

    /**
     * @notice Change the admin address
     * @param admin_ The address of the new admin
     */
    function setAdmin(address admin_) external onlySuperAdmin {
        admin = admin_;
    }

    /// Check EIP2981 supported contracts fro royalties
    function checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC165Upgradeable(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    // Marketplace functions
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        string calldata category
    ) public nonReentrant {
        require(listingIsActive == true, "Listing disabled");
        require(price > 0, "No item for free here");
        (bool isOwnerSupported, ) = nftContract.call(
            abi.encodeWithSignature("owner()")
        );
        if (isOwnerSupported) {
            contractOwners[nftContract] = IOwnable(nftContract).owner();
        }
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)), // No owner for the item
            0, // No offer
            payable(address(0)), // No bidder
            category,
            price,
            false
        );
        IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            category,
            price,
            false
        );
    }

    function updateMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 itemId
    ) public nonReentrant {
        require(listingIsActive == true, "Listing disabled");
        require(price > 0, "No item for free here");
        require(idToMarketItem[itemId].isSold == false, "Item is already sold");
        require(
            idToMarketItem[itemId].nftContract == nftContract,
            "Not correct NFT address"
        );
        require(
            idToMarketItem[itemId].tokenId == tokenId,
            "Not correct tokenId"
        );
        require(
            idToMarketItem[itemId].seller == msg.sender,
            "Only seller can update Item"
        );
        idToMarketItem[itemId].price = price;
        emit MarketItemUpdated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            idToMarketItem[itemId].category,
            price,
            false
        );
    }

    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        require(idToMarketItem[itemId].isSold == false, "Item is already sold");
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        address addressNFT = idToMarketItem[itemId].nftContract;
        require(addressNFT == nftContract, "Not correct NFT address");
        require(
            msg.value == price,
            "Please make the price to be same as listing price"
        );
        require(price > 0, "Item is already canceled");
        address sellerAddress = idToMarketItem[itemId].seller;
        uint marketFeeMultiplier=100;
        uint creatorFeeMultiplier = 100;
        uint256 creatorPayout = 0;
        address creator = address(0);
        // Read data from mappings
        creator = AddressToCreatorFeeItem[addressNFT].creator;
        if (creator != address(0x0)) {
            // if creator is set
            creatorPayout =
                ((msg.value / 10000) *
                    AddressToCreatorFeeItem[addressNFT].feeBasisPoints *
                    creatorFeeMultiplier) /
                100;
            //            payable(creator).transfer(creatorPayout);
            (bool success, ) = payable(creator).call{value: creatorPayout}("");
            require(success, "Transfer failed.");
        } else {
            if (checkRoyalties(addressNFT)) {
                (address creatorAddr, uint256 royalityAmt) = IERC2981Upgradeable(
                    addressNFT
                ).royaltyInfo(tokenId, msg.value);
                (bool success, ) = payable(creatorAddr).call{
                    value: royalityAmt
                }("");
                creatorPayout = royalityAmt;
                creator = creatorAddr;
                require(success, "Transfer failed.");
            }
        }
        // set in marketItem
        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].owner = payable(msg.sender);
        _itemsSold.increment();

        IERC721Upgradeable(nftContract).transferFrom(address(this), msg.sender, tokenId);

        // Calculate Payouts
        uint256 feePayout = ((msg.value / 10000) *
            salesFeeBasisPoints *
            marketFeeMultiplier) / 100;
        uint256 userPayout = msg.value - creatorPayout - feePayout;
        // Payout to user and owner (opentheta)
        //        payable(sellerAddress).transfer(userPayout);
        //        payable(feeAddress).transfer(feePayout);
        (bool successSeller, ) = payable(sellerAddress).call{value: userPayout}(
            ""
        );
        require(successSeller, "Transfer to seller failed.");
        (bool successOwner, ) = payable(feeAddress).call{value: feePayout}("");
        require(successOwner, "Transfer Fee failed.");
        MarketItem memory item = idToMarketItem[itemId];
        // Through events
        emit MarketItemSale(
            item.itemId,
            item.nftContract,
            item.tokenId,
            item.seller,
            item.owner,
            item.category,
            item.price,
            true
        );
        emit FeeSplit(
            userPayout,
            sellerAddress,
            feePayout,
            feeAddress,
            creatorPayout,
            creator
        );
    }

    function createMarketCancel(
        address nftContract,
        uint256 itemId
    ) public nonReentrant {
        require(
            msg.sender == idToMarketItem[itemId].seller,
            "You have to be the seller to cancel"
        );
        require(idToMarketItem[itemId].isSold == false, "Item is already sold");
        // Read data from mappings
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        // set in marketItem
        idToMarketItem[itemId].price = 0;
        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].owner = payable(idToMarketItem[itemId].seller);
        IERC721Upgradeable(nftContract).transferFrom(
            address(this),
            idToMarketItem[itemId].seller,
            tokenId
        );

        _itemsSold.increment();

        // Through event
        emit MarketItemSale(
            itemId,
            idToMarketItem[itemId].nftContract,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].seller,
            idToMarketItem[itemId].owner,
            idToMarketItem[itemId].category,
            0,
            true
        );
    }

    function createMarketCancelAdmin(
        address nftContract,
        uint256 itemId
    ) public nonReentrant onlyAdmin {
        require(idToMarketItem[itemId].isSold == false, "Item is already sold");
        // Read data from mappings
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        // set in marketItem
        idToMarketItem[itemId].price = 0;
        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].owner = payable(idToMarketItem[itemId].seller);
        IERC721Upgradeable(nftContract).transferFrom(
            address(this),
            idToMarketItem[itemId].seller,
            tokenId
        );


        _itemsSold.increment();

        // Through event
        emit MarketItemSale(
            itemId,
            idToMarketItem[itemId].nftContract,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].seller,
            idToMarketItem[itemId].owner,
            idToMarketItem[itemId].category,
            0,
            true
        );
    }
    
    /*
     * Pause listings if active
     */
    function flipListingState() public onlySuperAdmin {
        listingIsActive = !listingIsActive;
    }

    // set creator fee
    function setCreatorFeeBasisPoints(
        uint256 feeBasisPoints,
        address creatorAddress,
        address NFTAddress
    ) public onlyAdmin {
        require(feeBasisPoints <= 1000, "Sales Fee cant be higher than 10%");
        AddressToCreatorFeeItem[NFTAddress].feeBasisPoints = feeBasisPoints;
        AddressToCreatorFeeItem[NFTAddress].creator = payable(creatorAddress);
        emit CreatorFeeChanged(NFTAddress, creatorAddress, feeBasisPoints);
    }

    // set creator fee
    function setCreatorFeeBasisPointsByCreator(
        uint256 feeBasisPoints,
        address creatorAddress,
        address NFTAddress
    ) public {
        require(feeBasisPoints <= 1000, "Sales Fee cant be higher than 10%");
        require(contractOwners[NFTAddress] == msg.sender, "Not valid creator");
        AddressToCreatorFeeItem[NFTAddress].feeBasisPoints = feeBasisPoints;
        AddressToCreatorFeeItem[NFTAddress].creator = payable(creatorAddress);
        emit CreatorFeeChanged(NFTAddress, creatorAddress, feeBasisPoints);
    }

    // get creator fee
    function getCreatorFeeBasisPoints(
        address NFTAddress
    ) public view returns (Creator memory) {
        return AddressToCreatorFeeItem[NFTAddress];
    }

    function getByMarketId(uint256 id) public view returns (MarketItem memory) {
        require(id <= _itemIds.current(), "id doesn't exist");
        return idToMarketItem[id];
    }
    function getSalesFee() public view returns (uint256) {
        return salesFeeBasisPoints;
    }
    function getContractOwner(address contract_) public view returns (address) {
        return contractOwners[contract_];
    }
    
    function getLastMarketId() public view returns (uint256) {
        return _itemIds.current();
    }
}