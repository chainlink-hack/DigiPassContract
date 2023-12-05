const { ethers, network, run } = require("hardhat")
const {
    VERIFICATION_BLOCK_CONFIRMATIONS,
    networkConfig,
    developmentChains,
} = require("../../helper-hardhat-config")
const LINK_TOKEN_ABI = require("@chainlink/contracts/abi/v0.4/LinkToken.json")

async function deployContracts(chainId) {
    //set log level to ignore non errors
    ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)

    const accounts = await ethers.getSigners()
    const deployer = accounts[0]

    const sourceTicketPurchaser = await ethers.getContractFactory("SourceTicketPurchase");
    const deployedSourcePurchaser = await sourceTicketPurchaser.connect(deployer).deploy(networkConfig[chainId]["routerAddress"],networkConfig[chainId]["linkToken"]);


    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS
    await deployedSourcePurchaser.deployTransaction.wait(waitBlockConfirmations)

    console.log(`Source Ticket Purchaser deployed to ${deployedSourcePurchaser.address} on ${network.name}`)

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await run("verify:verify", {
            address: deployedSourcePurchaser.address,
            constructorArguments: [networkConfig[chainId]["routerAddress"],networkConfig[chainId]["linkToken"]],
        })
        console.log(`Source Ticket Purchaser address:  ${deployedSourcePurchaser.address} has been  verified on ${network.name}`);

    }

}

module.exports = {
    deployApiConsumer,
}
