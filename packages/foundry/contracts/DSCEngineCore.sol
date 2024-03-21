// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ethereis} from "./StablecoinToken.sol";
import {OracleLib, AggregatorV3Interface} from "../lib/OracleLib.sol";
import {DSCEngineSupport} from "./DSCEngineSupport.sol";

/**
 * @title DSCEngine - Core logic and Functions
 * @author dev.Patok
 */


contract DSCEngine is ReentrancyGuard, DSCEngineSupport {
    

    //////////////////////////////
    // Events | Mods | Vari     //
    //////////////////////////////
    event collateralDeposited(address indexed user, address indexed token, uint256 amount);
    event collateralRedeemed(address indexed from, address indexed to, address token, uint256 amount);


    Ethereis public immutable i_ETHRS;
    using OracleLib for AggregatorV3Interface;
    
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% over-collateralized
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% discount when liquidating
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant FEED_PRECISION = 1e8;
    uint256 private constant ADD_FEEDPRE = 1e10;
    uint256 private constant PRECISION = 1e18;

    mapping(address token => address priceFeed) public s_PriceFeed;
    mapping(address user => mapping(address token => uint256 amount)) private s_UserCollateral;
    mapping(address user => uint256 dscMintedAmount) private s_UserDSCMinted;
    address[] public s_collateralTokens;


    constructor (address[] memory _tokenAddresses, address[] memory _priceFeedAddresses, address _brscAddress) DSCEngineSupport(_brscAddress) {
        for (uint256 i = 0; i < _tokenAddresses.length; i++){
            s_PriceFeed[_tokenAddresses[i]] = _priceFeedAddresses[i];
        }
        if(_tokenAddresses.length != _priceFeedAddresses.length){
            revert Engine__TokenAddressAndPriceNotSameLength();
        }
        for(uint256 i = 0; i < _tokenAddresses.length; i++){
            s_PriceFeed[_tokenAddresses[i]] = _priceFeedAddresses[i];
            s_collateralTokens.push(_tokenAddresses[i]);
        }
        i_ETHRS = Ethereis(_brscAddress);
        
    }

    /////////////////
    // Functions  
    ///////////////    
    function depositCollMintBrsc (address _tokenCollateral, uint256 _collAmount, uint256 _brscToMint) external {
        depositCollateral(_tokenCollateral, _collAmount);
        mintBrsc(_brscToMint);
    }

    function depositCollateral (address _tokenCollateralAddress, uint256 _amountCollateral) 
        public 
        moreThanZero(_amountCollateral)
        isTokenAllowed(_tokenCollateralAddress)
        nonReentrant() {
        
        s_UserCollateral[msg.sender][_tokenCollateralAddress] += _amountCollateral;
        emit collateralDeposited(msg.sender, _tokenCollateralAddress, _amountCollateral);
        (bool success) = IERC20(_tokenCollateralAddress).transferFrom(msg.sender, address(this), _amountCollateral);
        if (!success){
            revert Engine__TransferFailed();
        }
    }

    function redeemCollateral (address _tokenCollateral, uint256 _collAmount) external moreThanZero(_collAmount) isTokenAllowed(_tokenCollateral) nonReentrant {
        uint256 userCollateral = s_UserCollateral[msg.sender][_tokenCollateral];
        if (userCollateral < _collAmount){
            revert Engine__NotEnoughCollateral();
        }
        _redeemCollateral(_tokenCollateral, _collAmount, msg.sender, msg.sender);
    }

    // function redeemCollwithBrsc () external {}

    function mintBrsc(uint256 _amountToMint) public moreThanZero(_amountToMint) {
        s_UserDSCMinted[msg.sender] += _amountToMint;
        _revertIfLowHealthFactor(msg.sender);

        bool minted = i_ETHRS.mint(msg.sender, _amountToMint);
        if (!minted){
            revert Engine__MintFailed();
        }
    }

    function burnBrsc (uint256 _amount) external moreThanZero(_amount) {
        _burnDsc(_amount, msg.sender, msg.sender);
        _revertIfLowHealthFactor(msg.sender);
    }

    function liquidate (address _collateral, address _user, uint256 _Debt) external moreThanZero(_Debt) nonReentrant {
        uint256 StartingHealth = _healthFactor(_user);
        if (StartingHealth >= MIN_HEALTH_FACTOR){
            revert Engine__HighHealth();
        }
        uint256 tokenDebtPaid = getUSDValueOfToken(_collateral, _Debt);
        // uint256 bonus = (tokenDebtPaid * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        _burnDsc(_Debt, _user, msg.sender);
        uint256 EndingHelath = _healthFactor(_user);
        if(EndingHelath <= StartingHealth){
            revert Engine__LowHealthFactor(EndingHelath);
        }
        _revertIfLowHealthFactor(msg.sender);
    }

    ////////////////////
    /// Low
    /////////
    function AccountCollateralValue(address _user) public view returns(uint256 collateralValueInUSD) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_UserCollateral[_user][token];
            collateralValueInUSD += getUSDValueOfToken(token, amount);
        }
    }

    function getUSDValueOfToken(address _token, uint256 _amount) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_PriceFeed[_token]);
        (, int price, , , ) = priceFeed.latestRoundData();
        return ((uint256(price) * ADD_FEEDPRE) * _amount) / PRECISION;
    }

    function _burnDsc(uint256 _amountburn, address _of, address _dscFrom) private {
        s_UserDSCMinted[_of] -= _amountburn;

        bool success = i_ETHRS.transferFrom(_dscFrom, address(this), _amountburn);
        // This conditional is hypothetically unreachable
        if (!success) {
            revert Engine__TransferFailed();
        }
        i_ETHRS.burn(_amountburn);
    }
    function _getAddressInfo(address _user) private view returns(uint256 totalMintedDSCis, uint256 collateralValueUSD) {
        totalMintedDSCis = s_UserDSCMinted[_user];
        collateralValueUSD = AccountCollateralValue(_user);
    }

    function _redeemCollateral(address _Token, uint256 _amountToken, address _from, address _to) private {
        s_UserCollateral[_from][_Token] -= _amountToken;
        emit collateralRedeemed(_from, _to, _Token, _amountToken);
        bool success = IERC20(_Token).transfer(_to, _amountToken);
        if (!success) {
            revert Engine__NotEnoughCollateral();
        }
    }

    function _healthFactor(address _user) private view returns(uint256) {
        (uint256 totalMintedDSC, uint256 collateralValueUSD) = _getAddressInfo(_user);
        return _calculateHealthFactor(totalMintedDSC, collateralValueUSD);
    }

    function _calculateHealthFactor(uint _totalMintedDSC, uint _collateralValueUSD) internal pure returns(uint256) {
        if (_totalMintedDSC == 0) return type(uint256).max;
        uint256 collateralAdjusted = (_collateralValueUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjusted * PRECISION) / _totalMintedDSC;
    }

    function _revertIfLowHealthFactor(address _user) internal view {
        uint256 userHealth = _healthFactor(_user);
        if (userHealth < MIN_HEALTH_FACTOR){
            revert Engine__LowHealthFactor(userHealth);
        }
    }

}