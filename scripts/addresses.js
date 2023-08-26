const WBNB = artifacts.require("WBNB")
const TokenA = artifacts.require("TokenA")
const TokenB = artifacts.require("TokenB")
const Multicall = artifacts.require("Multicall")

module.exports = async (callback) => {
  const wbnb = await WBNB.deployed()
  const tokena = await TokenA.deployed()
  const tokenb = await TokenB.deployed()
  const mc = await Multicall.deployed()

  console.log(`WBNB: ${wbnb.address}`)
  console.log(`TokenA: ${tokena.address}`)
  console.log(`TokenB: ${tokenb.address}`)
  console.log("-----")
  console.log(`Multicall: ${mc.address}`)

  callback()
}