//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

<<<<<<< Updated upstream
import {Script} from "@forge-std/Script.sol";
import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
import {Ethereis} from "../contracts/StablecoinToken.sol";
import {DSCEngine} from "../contracts/DSCEngineCore.sol";

contract DSCEngineDeploy is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);
=======
import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
import {Ethereis} from "../contracts/Etheris.sol";
import {DSCEngine} from "../contracts/DSCEngine.sol";

contract DSCEngineDeploy is ScaffoldETHDeploy {
    error InvalidPrivateKey(string); 
>>>>>>> Stashed changes

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    function run() external {
<<<<<<< Updated upstream
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
=======
        ScaffoldETHDeploy helperConfig = new ScaffoldETHDeploy(); // This comes with our mocks!

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();
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
        vm.stopBroadcast();
        exportDeployments();
>>>>>>> Stashed changes
    }
    function test() public {}
}
