// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet is Ownable {
    uint256  public tokenAmount = 1000 * 10**18;
    uint256  public waitTime = 1 days;

    ERC20 public tokenInstance;
    
    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance) {
        require(_tokenInstance != address(0));
        tokenInstance = ERC20(_tokenInstance);
    }

    function requestTokens() public {
        require(allowedToWithdraw(msg.sender), "Token already claimed for the day.");
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }

    function updateTokenAmount(uint256 newAmount) public onlyOwner {
        tokenAmount = newAmount;
    }

    function updateDateTimeMinutes(uint256 newTime) public onlyOwner {
        waitTime = newTime * 1 minutes;
    }
    
    function withdraw() public onlyOwner {
        tokenInstance.transfer(owner(), tokenInstance.balanceOf(address(this)));
    }
}