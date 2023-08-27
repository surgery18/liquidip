const DEXFactory = artifacts.require("DEXFactory")
const WBNB = artifacts.require("WBNB")
const TokenA = artifacts.require("TokenA")
const TokenB = artifacts.require("TokenB")
const ArbitrageFactory = artifacts.require("ArbitrageFactory")
// const Multicall = artifacts.require("Multicall")

module.exports = async function (deployer, network, accounts) {
	//Deploy TEST COINS
	await deployer.deploy(WBNB)
	await deployer.deploy(TokenA)
	await deployer.deploy(TokenB)

	//Deploy Multicall - not used
	// await deployer.deploy(Multicall)

	// Deploy DEXFactory
	await deployer.deploy(DEXFactory)
	const dexFactory = await DEXFactory.deployed()

	//create Arb Factory
	await deployer.deploy(ArbitrageFactory)

	//create 2 dexes
	// await dexFactory.createDex()
	// await dexFactory.createDex()
}
