// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev OCTO NFT collection commenting.
 * @author Omsify
 */
contract NFTCollectionCommentsUpgradeable is Initializable, OwnableUpgradeable {
    IERC20Upgradeable public erc20Token;
    struct Comment {
        address commenter;
        uint256 timestamp;
        string contents;
    }

    error WrongValue();
    error WithdrawError();
    error LowBalance();
    error SpendingNotApproved();

    uint256 public commentFee;

    event CollectionCommentPosted(
        address indexed collectionAddress,
        address indexed senderAddress,
        uint256 timestamp,
        string comment
    );

    function init(address token) public initializer {
        __Ownable_init();
        erc20Token = IERC20Upgradeable(token);
        commentFee = 1 ether; //1 TFuel
    }

    // Mapping from NFT collection address => comments related to this specific collection.
    mapping(address => Comment[]) private collectionComments;

    /**
     * @dev Stores a comment with text `contents` related to
     * NFT with address `nftAddress` and token id `tokenId` in the contract.
     * Transaction value should equal current commentFee.
     */
    function addComment_native(
        address nftAddress,
        string calldata contents
    ) public payable {
        if (msg.value != commentFee) revert WrongValue();

        collectionComments[nftAddress].push(
            Comment(msg.sender, block.timestamp, contents)
        );
        emit CollectionCommentPosted(
            nftAddress,
            msg.sender,
            block.timestamp,
            contents
        );
    }

    function addComment_erc20(
        address nftAddress,
        string calldata contents
    ) public {
        if (erc20Token.balanceOf(msg.sender) < commentFee) revert LowBalance();
        if (erc20Token.allowance(msg.sender, address(this)) < commentFee)
            revert SpendingNotApproved();

        collectionComments[nftAddress].push(
            Comment(msg.sender, block.timestamp, contents)
        );

        emit CollectionCommentPosted(
            nftAddress,
            msg.sender,
            block.timestamp,
            contents
        );
        erc20Token.transferFrom(msg.sender, address(this), commentFee);
    }

    /**
     * @dev Withdraws fee to the contract owner address.
     */
    function withdrawFees() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        if (!sent) revert WithdrawError();
    }

    /**
     * @dev Withdraws fee to the contract owner address.
     */
    function withdrawFeesERC20() public onlyOwner {
        erc20Token.transfer(owner(), erc20Token.balanceOf(address(this)));
    }

    /**
     * @dev changes erc20 fee token.
     */
    function changeERC20FeeToken(address newToken) public onlyOwner {
        erc20Token = IERC20Upgradeable(newToken);
    }

    /**
     * @dev Updates commentFee amount.
     */
    function updateFee(uint256 newCommentFee) public onlyOwner {
        commentFee = newCommentFee;
    }

    /**
     * @dev Returns a comment related to
     * NFT collection with address `nftAddress` at `index` from the contract.
     */
    function getComment(
        address nftAddress,
        uint256 index
    )
        external
        view
        returns (address commenter, uint256 timestamp, string memory contents)
    {
        Comment storage comment = collectionComments[nftAddress][index];
        return (comment.commenter, comment.timestamp, comment.contents);
    }

    /**
     * @dev Returns a comment array related to
     * NFT collection with address `nftAddress` from the contract.
     */
    function getAllCommentsOf(
        address nftAddress
    ) external view returns (Comment[] memory) {
        return collectionComments[nftAddress];
    }
}
