// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Ethereis is ERC20Burnable, Ownable {

    error ETHRS__MoreThanZero();
    error ETHRS__BurnAmountExceeds();
    error ETHRS__MustBeZeroAddress();
    
    constructor() ERC20("Ethereis", "ETHRS") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert ETHRS__MoreThanZero();
        }
        if (balance < _amount) {
            revert ETHRS__BurnAmountExceeds();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert ETHRS__MustBeZeroAddress();
        }
        if (_amount <= 0) {
            revert ETHRS__MoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }


}