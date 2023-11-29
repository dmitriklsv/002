// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OCTOToken is ERC20 {
    constructor() ERC20("OCTO Token", "OCTO") {
        _mint(msg.sender, 1000000000 * 10 ** uint256(decimals()));
    }
}