const { ethers, network, run } = require("hardhat")
const {
    VERIFICATION_BLOCK_CONFIRMATIONS,
    networkConfig,
    developmentChains,
} = require("../../helper-hardhat-config")


async function deployDigiPassContracts(chainId) {
    //set log level to ignore non errors
    // ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)
console.log(`Deploying ${chainId} ${networkConfig[chainId]["ccipBNM"]}`)
    const account= await ethers.getSigners();
    const deployer = account[0];
    
    const digiPassContractFactory = await ethers.getContractFactory("DigiPass");
    // console.log("factory:: ", digiPassContractFactory)
    const deployedDigiPassContract = await digiPassContractFactory
        .connect(deployer)
        .deploy(networkConfig[chainId]["routerAddress"], networkConfig[chainId]["ccipBNM"])

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS
        const confiredDeployedContract = await deployedDigiPassContract.waitForDeployment(waitBlockConfirmations)
     console.log(
         "deployedDigiPassContract",
         networkConfig[chainId]["routerAddress"],
         networkConfig[chainId]["ccipBNM"],
         confiredDeployedContract.target
     )
    

    console.log(
        `DigiPass Contract deployed to ${confiredDeployedContract.target} on ${network.name}  ${
            process.env.ETHERSCAN_API_KEY
        } does not exist ${!developmentChains.includes(network.name)}`
    )

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await run("verify:verify", {
            address: confiredDeployedContract.target,
            constructorArguments: [
                networkConfig[chainId]["routerAddress"],
                networkConfig[chainId]["ccipBNM"],
            ],
        })
        console.log(
            `Digipass Contract address:  ${confiredDeployedContract.target} has been  verified on ${network.name}`
        )
    }
}

module.exports = {
    deployDigiPassContracts,
}
