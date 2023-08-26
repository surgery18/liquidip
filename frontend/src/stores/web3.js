import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import DexFactoryContract from '../../../build/contracts/DEXFactory.json';
import Web3 from "web3"

const isTest = true
const nodeUrl = 'ws://localhost:8545'

export const useWeb3Store = defineStore('web3', () => {
  const web3 = ref(null)
  const currentAddress = ref(null)
  const dexFactory = ref(null)
  const networkId = ref(null)
  const arbFactory = ref(null)

  const shortAddress = computed(() =>
    currentAddress.value
      ? `${currentAddress.value.slice(0, 6)}...${currentAddress.value.slice(-4)}`
      : ""
  )

  async function initializeWeb3() {
    // console.log(Web3.givenProvider)
    web3.value = new Web3(Web3.givenProvider || nodeUrl)
    // web3.value = new Web3(nodeUrl)
    const accounts = await web3.value.eth.getAccounts();
    if (accounts && accounts.length > 0) {
      currentAddress.value = accounts[0];
    }
  }

  async function connect() {
    if (web3.value && web3.value.currentProvider && typeof web3.value.currentProvider.request === 'function') {
      const accounts = await web3.value.currentProvider.request({ method: 'eth_requestAccounts' });
      currentAddress.value = accounts[0];

      //loadContracts();
    } else {
      throw new Error('Please install MetaMask or another web3 provider.');
    }
  }

  function loadContracts() {
    if (!web3.value) {
      console.error('Web3 is not initialized');
      return;
    }

    const networks = Object.keys(DexFactoryContract.networks)
    const network = networks[networks.length - 1]
    networkId.value = network
    const dfa = DexFactoryContract.networks[network].address
    // console.log(dfa)
    dexFactory.value = new web3.value.eth.Contract(DexFactoryContract.abi, dfa);
    // arbFactory.value = new web3.value.eth.Contract(ArbFactoryContractABI, "ArbFactoryContractAddress");
  }

  return {
    web3,
    currentAddress,
    shortAddress,
    dexFactory,
    networkId,
    initializeWeb3,
    connect,
    loadContracts
  }
})
