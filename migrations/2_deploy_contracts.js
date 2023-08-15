const DEXFactory = artifacts.require("DEXFactory")
const WBNB = artifacts.require("WBNB")

module.exports = async function (deployer, network, accounts) {
	//Deploy WBNB
	await deployer.deploy(WBNB)
	const wbnb = await WBNB.deployed()

	// Deploy DEXFactory
	await deployer.deploy(DEXFactory)
	const dexFactory = await DEXFactory.deployed()

	//create 2 dexes
	await dexFactory.createDex()
	await dexFactory.createDex()
}
