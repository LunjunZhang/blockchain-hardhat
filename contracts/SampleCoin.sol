// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Uncomment this line to use console.log
import "hardhat/console.sol";

contract SampleCoin is ERC20 {
    // Define constants for token details to make the code more readable.
    string private constant TOKEN_NAME = "ExampleToken";
    string private constant TOKEN_SYMBOL = "EXM";
    uint256 private constant INITIAL_SUPPLY = 1e20; // Equivalent to 100 with 18 decimal places.

    // The constructor sets up the new token with a predetermined supply.
    constructor() payable ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        _createInitialSupply(msg.sender, INITIAL_SUPPLY);
    }

    // Internal function to create the initial supply of the token.
    function _createInitialSupply(address to, uint256 amount) internal {
        _mint(to, amount);
    }

}