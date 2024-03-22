// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

<<<<<<< Updated upstream
import {DSCEngine} from "./DSCEngineCore.sol";
=======
import {DSCEngine} from "./DSCEngine.sol";
>>>>>>> Stashed changes

contract DSCEngineSupport {

    DSCEngine engineCore;

    error Engine__NotMoreThanZero();
    error Engine__TokenAddressAndPriceNotSameLength();
    error Engine__TokenNotSupported();
    error Engine__TransferFailed();
    error Engine__LowHealthFactor(uint256 healthFactor);
    error Engine__MintFailed();
    error Engine__HighHealth();
    error Engine__NotEnoughCollateral();
    constructor(address _EngineCoreAddress) {
        engineCore = DSCEngine(_EngineCoreAddress);
    }

    modifier moreThanZero (uint256 _amount) {
        if (_amount == 0){
            revert Engine__NotMoreThanZero();
        }
        _;
    }

    modifier isTokenAllowed (address _tokenAddress) {
        
        if (getPriceFeed(_tokenAddress) == address(0)){
            revert Engine__TokenNotSupported();
        }
        _;
    }

    function getPriceFeed(address _tokenAddress) public view returns (address) {
        return engineCore.s_PriceFeed(_tokenAddress);
    }

}