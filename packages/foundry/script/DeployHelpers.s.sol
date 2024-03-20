//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract ScaffoldETHDeploy is Script {
    error InvalidChain();
    NetworkConfig public activeNetworkConfig;


    struct Deployment {
        string name;
        address addr;
    }

    string root;
    string path;

    Deployment[] public deployments;

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;

    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306, // ETH / USD
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            ETH_USD_PRICE
        );
        ERC20Mock wethMock = new ERC20Mock();

        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            BTC_USD_PRICE
        );
        ERC20Mock wbtcMock = new ERC20Mock();
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: address(ethUsdPriceFeed), // ETH / USD
            weth: address(wethMock),
            wbtcUsdPriceFeed: address(btcUsdPriceFeed),
            wbtc: address(wbtcMock),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }

        
    function setupLocalhostEnv()
        internal
        returns (uint256 localhostPrivateKey)
    {
        if (block.chainid == 31337) {
            root = vm.projectRoot();
            path = string.concat(root, "/localhost.json");
            string memory json = vm.readFile(path);
            bytes memory mnemonicBytes = vm.parseJson(json, ".wallet.mnemonic");
            string memory mnemonic = abi.decode(mnemonicBytes, (string));
            return vm.deriveKey(mnemonic, 0);
        } else {
            return vm.envUint("DEPLOYER_PRIVATE_KEY");
        }
    }

    function exportDeployments() internal {
        // fetch already existing contracts
        root = vm.projectRoot();
        path = string.concat(root, "/deployments/");
        string memory chainIdStr = vm.toString(block.chainid);
        path = string.concat(path, string.concat(chainIdStr, ".json"));

        string memory jsonWrite;

        uint256 len = deployments.length;

        for (uint256 i = 0; i < len; i++) {
            vm.serializeString(
                jsonWrite, vm.toString(deployments[i].addr), deployments[i].name
            );
        }

        string memory chainName;

        try this.getChain() returns (Chain memory chain) {
            chainName = chain.name;
        } catch {
            chainName = findChainName();
        }
        jsonWrite = vm.serializeString(jsonWrite, "networkName", chainName);
        vm.writeJson(jsonWrite, path);
    }

    function getChain() public returns (Chain memory) {
        return getChain(block.chainid);
    }

    function findChainName() public returns (string memory) {
        uint256 thisChainId = block.chainid;
        string[2][] memory allRpcUrls = vm.rpcUrls();
        for (uint256 i = 0; i < allRpcUrls.length; i++) {
            try vm.createSelectFork(allRpcUrls[i][1]) {
                if (block.chainid == thisChainId) {
                    return allRpcUrls[i][0];
                }
            } catch {
                continue;
            }
        }
        revert InvalidChain();
    }
}
