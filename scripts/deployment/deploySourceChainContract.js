const { ethers, network, run } = require("hardhat")
const {
    VERIFICATION_BLOCK_CONFIRMATIONS,
    networkConfig,
    developmentChains,
} = require("../../helper-hardhat-config")
// const LINK_TOKEN_ABI = require("@chainlink/contracts/abi/v0.4/LinkToken.json")

async function deploySourceChainContracts(chainId) {
    console.log("should run")
    //set log level to ignore non errors
    // ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)

    const accounts = await ethers.getSigners()
    const deployer = accounts[0]

    const sourceTicketPurchaser = await ethers.getContractFactory("SourceTicketPurchase");
    const deployedSourcePurchaser = await sourceTicketPurchaser
        .connect(deployer)
        .deploy(
            networkConfig[chainId]["routerAddress"],
            networkConfig[chainId]["linkToken"],
            networkConfig[chainId]["ccipBNM"]
        );
 

    console.log("sourceTicketPurchaser", deployedSourcePurchaser)
    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS
    const confirmedDeployedSourcePurchaser = await deployedSourcePurchaser.waitForDeployment(waitBlockConfirmations);

    console.log(
        `Source Ticket Purchaser deployed to ${confirmedDeployedSourcePurchaser.target} on ${network.name}`
    )

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await run("verify:verify", {
            address: confirmedDeployedSourcePurchaser.target,
            constructorArguments: [
                networkConfig[chainId]["routerAddress"],
                networkConfig[chainId]["linkToken"],
            ],
        })
        console.log(
            `Source Ticket Purchaser address:  ${confirmedDeployedSourcePurchaser.target} has been  verified on ${network.name}`
        )

    }

}

module.exports = {
    deploySourceChainContracts,
}
