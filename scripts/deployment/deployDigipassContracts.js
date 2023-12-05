const { ethers, network, run } = require("hardhat")
const {
    VERIFICATION_BLOCK_CONFIRMATIONS,
    networkConfig,
    developmentChains,
} = require("../../helper-hardhat-config")


async function deployDestinationChainContracts(chainId) {
    //set log level to ignore non errors
    ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)

    const accounts = await ethers.getSigners()
    const deployer = accounts[0]

    const digiPassContract = await ethers.getContractFactory("DigiPass");
    const deployedDigiPassContract = await digiPassContract.connect(deployer).deploy();

    const destinationTicketPurchaser = await ethers.getContractFactory("DestinationTicketPurchaser");
    const deployedDestinationPurchaser = await destinationTicketPurchaser.connect(deployer).deploy(networkConfig[chainId]["routerAddress"],deployedDigiPassContract.address);

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS
    
    await deployedDigiPassContract.deployTransaction.wait(waitBlockConfirmations)
    await deployedDestinationPurchaser.deployTransaction.wait(waitBlockConfirmations)

    console.log(`DigiPass Contract deployed to ${deployedDigiPassContract.address} on ${network.name}`)
    console.log(`Destination Ticket Purchaser deployed to ${deployedDestinationPurchaser.address} on ${network.name}`)

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await run("verify:verify", {
            address: deployedDigiPassContract.address,
            constructorArguments: [],
        });
        console.log(`Digipass Contract address:  ${deployedDigiPassContract.address} has been  verified on ${network.name}`);
        await run("verify:verify", {
            address: deployedDestinationPurchaser.address,
            constructorArguments: [networkConfig[chainId]["routerAddress"],deployedDigiPassContract.address],
        });
          console.log(`Destination Chain Contract address:  ${deployedDestinationPurchaser.address} has been  verified on ${network.name}`);
    }
}

module.exports = {
    deployDestinationChainContracts,
}
