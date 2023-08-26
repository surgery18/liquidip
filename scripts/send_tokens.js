const WBNB = artifacts.require("WBNB")
const TokenA = artifacts.require("TokenA")
const TokenB = artifacts.require("TokenB")

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const ta = await TokenA.deployed()
  const tb = await TokenB.deployed()

  const balA = await ta.balanceOf(accounts[0])
  const balB = await tb.balanceOf(accounts[0])

  const outside = "";
  await ta.transfer(outside, balA, { from: accounts[0] })
  await tb.transfer(outside, balB, { from: accounts[0] })


  //get some WBNB
  const wbnb = await WBNB.deployed()
  //deposit some BNB TO WBNB
  for (const account of accounts) {
    await wbnb.deposit({ from: account, value: web3.utils.toWei("0.01", "ether") })
    //transfer
    await wbnb.transfer(outside, web3.utils.toWei("0.01", "ether"), { from: account })
  }
  callback()
}