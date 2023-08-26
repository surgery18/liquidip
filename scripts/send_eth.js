async function sendEth() {
  const accounts = await web3.eth.getAccounts();
  for (const account of accounts) {
    await web3.eth.sendTransaction({ from: account, to: "", value: web3.utils.toWei('1', 'ether') })
  }
}

module.exports = async (callback) => {
  await sendEth()
  callback()
}