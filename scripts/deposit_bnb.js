const WBNB = artifacts.require("WBNB")

module.exports = async (callback) => {
    const accounts = await web3.eth.getAccounts();
    const wbnb = await WBNB.deployed()
    await wbnb.deposit({ from: accounts[0], value: web3.utils.toWei("5", "ether") })
    callback()
}