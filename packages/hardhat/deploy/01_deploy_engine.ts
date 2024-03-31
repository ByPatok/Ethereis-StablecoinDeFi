import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

const deployEngine: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network sepolia`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("Engine", {
    from: deployer,
    // Contract constructor arguments
    args: [deployer],
    log: true,
    autoMine: true,
  });
  // Get the deployed contract to interact with it after deploying.

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const Engine = await hre.ethers.getContract<Contract>("Engine", deployer);
  // const Ethereis = await hre.ethers.getContract<Contract>("Ethereis", deployer);

  // const transferOwnershipTx = await Ethereis.transferOwnership(Engine.address);
  // await transferOwnershipTx.wait();
};

export default deployEngine;

deployEngine.tags = ["YourContract"];