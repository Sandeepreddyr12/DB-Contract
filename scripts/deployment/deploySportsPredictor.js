const { ethers, network, run } = require("hardhat")
const {
    VERIFICATION_BLOCK_CONFIRMATIONS,
    networkConfig,
    developmentChains,
} = require("../../helper-hardhat-config")

async function deploySportsPredictor() {
    const chainId = network.config.chainId
    console.log(chainId);
    const raffleEntranceFee = ethers.utils.parseEther("0.01")
    const automationUpdateInterval = networkConfig[chainId]["automationUpdateInterval"]

    const sportsPredictorFactory = await ethers.getContractFactory("sportsPredictor")
    const sportsPredictor = await sportsPredictorFactory.deploy(
        raffleEntranceFee,
        automationUpdateInterval
    )

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS
    await sportsPredictor.deployTransaction.wait(waitBlockConfirmations)

    console.log(`sportsPredictor deployed to ${sportsPredictor.address} on ${network.name}`)

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await run("verify:verify", {
            address: sportsPredictor.address,
            constructorArguments: [automationUpdateInterval],
        })
    }
}

deploySportsPredictor().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

// module.exports = {
//     deploySportsPredictor,
// }
