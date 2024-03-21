//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "@forge-std/Script.sol";
import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
import {Ethereis} from "../contracts/StablecoinToken.sol";
import {DSCEngine} from "../contracts/DSCEngineCore.sol";

contract DSCEngineDeploy is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
    }
    function test() public {}
}
