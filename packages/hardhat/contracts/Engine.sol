// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ethereis} from "./Ethereis.sol";

contract Engine is ReentrancyGuard {

    Ethereis public immutable i_ETHRS; 

    event collateralDeposited(address indexed user, address indexed token, uint256 amount);
    event collateralRedeemed(address indexed from, address indexed to, address token, uint256 amount);

    error Engine__NotMoreThanZero();
    error Engine__TransferFailed();
    error Engine__LowHealthFactor(uint256 healthFactor);
    error Engine__MintFailed();
    error Engine__HighHealth();
    error Engine__NotEnoughCollateral();

    mapping(address user => mapping(address token => uint256 amount)) private s_UserCollateral;
    mapping(address user => uint256 MintedAmount) private s_UserAmountMinted;

    modifier moreThanZero (uint256 _amount) {
        if (_amount == 0){
            revert Engine__NotMoreThanZero();
        }
        _;
    }

    constructor(address _deployer) {
        i_ETHRS = Ethereis(_deployer);
    }


}