//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
import {Ethereis} from "../contracts/BrazilianStablecoin.sol";
import {DSCEngine} from "../contracts/DSCEngine.sol";

contract DSCEngineDeploy is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    uint256 public chainid;

    function run() external returns (Ethereis, DSCEngine, ScaffoldETHDeploy) {
        ScaffoldETHDeploy helperConfig = new ScaffoldETHDeploy(); 
        chainid = helperConfig.getChain();
        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey
        ) =helperConfig.activeNetworkConfig();
        
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        Ethereis dsc = new Ethereis();
        DSCEngine dscEngine = new DSCEngine(
            tokenAddresses,
            priceFeedAddresses,
            address(dsc)
        );
        dsc.transferOwnership(address(dscEngine));
        exportDeployments(); 
        vm.stopBroadcast();
        return (dsc, dscEngine, helperConfig); 
    }
    function getChain() public view returns  (uint256) {
        return chainid;
    }

    function test() public {}
}
