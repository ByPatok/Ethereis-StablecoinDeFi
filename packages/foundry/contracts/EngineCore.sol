//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ethereis} from "./Ethereis.sol";

contract EngineCore is ReentrancyGuard {

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
    mapping(address user => uint256 dscMintedAmount) private s_UserDSCMinted;

    modifier moreThanZero (uint256 _amount) {
        if (_amount == 0){
            revert Engine__NotMoreThanZero();
        }
        _;
    }

    constructor(address _deployer) {
        i_ETHRS = Ethereis(_deployer);
    }

    function depositCollMintBrsc (address _tokenCollateral, uint256 _collAmount, uint256 _brscToMint) external {
        depositCollateral(_tokenCollateral, _collAmount);
        mintBrsc(_brscToMint);
    }

    function depositCollateral (address _tokenCollateralAddress, uint256 _amountCollateral) public moreThanZero(_amountCollateral) nonReentrant() {
        
        s_UserCollateral[msg.sender][_tokenCollateralAddress] += _amountCollateral;
        emit collateralDeposited(msg.sender, _tokenCollateralAddress, _amountCollateral);
        (bool success) = IERC20(_tokenCollateralAddress).transferFrom(msg.sender, address(this), _amountCollateral);
        if (!success){
            revert Engine__TransferFailed();
        }
    }

    function mintBrsc(uint256 _amountToMint) public moreThanZero(_amountToMint) {
        s_UserDSCMinted[msg.sender] += _amountToMint;
        // _revertIfLowHealthFactor(msg.sender);

        bool minted = i_ETHRS.mint(msg.sender, _amountToMint);
        if (!minted){
            revert Engine__MintFailed();
        }
    }

    // function _revertIfLowHealthFactor(address _user) internal view {
    //     uint256 userHealth = _healthFactor(_user);
    //     if (userHealth < MIN_HEALTH_FACTOR){
    //         revert Engine__LowHealthFactor(userHealth);
    //     }
    // }

    // function _healthFactor(address _user) private view returns(uint256) {
    //     (uint256 totalMintedDSC, uint256 collateralValueUSD) = _getAddressInfo(_user);
    //     return _calculateHealthFactor(totalMintedDSC, collateralValueUSD);
    // }

    // function _calculateHealthFactor(uint _totalMintedDSC, uint _collateralValueUSD) internal pure returns(uint256) {
    //     if (_totalMintedDSC == 0) return type(uint256).max;
    //     uint256 collateralAdjusted = (_collateralValueUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
    //     return (collateralAdjusted * PRECISION) / _totalMintedDSC;
    // }


}