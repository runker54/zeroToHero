// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Runker54 is ERC20 {
    constructor() ERC20("Runker54", "R54") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}
