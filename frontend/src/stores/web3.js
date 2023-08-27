import { ref, computed } from "vue"
import { defineStore } from "pinia"
import DexFactoryContract from "../../../build/contracts/DEXFactory.json"
import Web3 from "web3"
import DEX from "../../../build/contracts/DEX.json"

const isTest = false
const nodeUrl = isTest
	? "ws://localhost:8545"
	: "wss://crimson-purple-wildflower.bsc-testnet.discover.quiknode.pro/0a72bbf19b1572ede064556ee0073ef67af631ce/"

export const useWeb3Store = defineStore("web3", () => {
	const web3 = ref(null)
	const currentAddress = ref(null)
	const dexFactory = ref(null)
	const networkId = ref(null)
	const arbFactory = ref(null)

	const shortAddress = computed(() =>
		currentAddress.value
			? `${currentAddress.value.slice(0, 6)}...${currentAddress.value.slice(
					-4
			  )}`
			: ""
	)

	async function initializeWeb3() {
		// console.log(Web3.givenProvider)
		web3.value = new Web3(Web3.givenProvider || nodeUrl)

		const nid = await web3.value.eth.net.getId()
		if (!isTest && nid !== 97) {
			throw new Error("Wrong network")
		}
		// web3.value = new Web3(nodeUrl)
		const accounts = await web3.value.eth.getAccounts()
		if (accounts && accounts.length > 0) {
			currentAddress.value = accounts[0]
		}
	}

	async function connect() {
		if (
			web3.value &&
			web3.value.currentProvider &&
			typeof web3.value.currentProvider.request === "function"
		) {
			const nid = await web3.value.eth.net.getId()
			if (!isTest && nid !== 97) {
				alert("SWITCH NETWORK TO BNB TESTNET BEFORE CONNECTING!")
				throw new Error("Wrong network")
			}
			const accounts = await web3.value.currentProvider.request({
				method: "eth_requestAccounts",
			})
			currentAddress.value = accounts[0]
			//loadContracts();
		} else {
			throw new Error("Please install MetaMask or another web3 provider.")
		}
	}

	async function loadContracts() {
		if (!web3.value) {
			console.error("Web3 is not initialized")
			return
		}
		const nid = await web3.value.eth.net.getId()
		if (!isTest && nid !== 97) {
			console.error("Wrong network")
			throw new Error("Wrong network")
		}

		const networks = Object.keys(DexFactoryContract.networks)
		if (isTest) {
			const network = networks[networks.length - 1]
			networkId.value = network
			// console.log(networks)
		} else {
			networkId.value = 97
		}
		// console.log(networkId.value)
		const dfa = DexFactoryContract.networks[networkId.value].address
		// console.log(dfa)
		dexFactory.value = new web3.value.eth.Contract(DexFactoryContract.abi, dfa)
		// arbFactory.value = new web3.value.eth.Contract(ArbFactoryContractABI, "ArbFactoryContractAddress");
	}

	async function calcProfits(dexA, dexB, t0, t1, borrowed) {
		//calculate estimate profit
		const dac = new web3.value.eth.Contract(DEX.abi, dexA)
		const dbc = new web3.value.eth.Contract(DEX.abi, dexB)

		// const route = [t0, t1]
		const route = await dac.methods.getRoute(t0, t1).call()
		// console.log(route)

		// const borrowed = 1
		const fee = borrowed * 0.0005 //0.05%

		const aBalwei = await dac.methods
			.estimateOutput(
				route,
				web3.value.utils.toWei(borrowed.toString(), "ether")
			)
			.call()

		const bBalwei = await dbc.methods
			.estimateOutput(route.slice(-2).reverse(), aBalwei)
			.call()
		const bal = +web3.value.utils.fromWei(bBalwei, "ether")

		const estimatedProfit = bal - (borrowed + fee)
		// console.log(borrowed, fee, estimatedProfit)
		const profitable = estimatedProfit > 0
		return {
			estimatedProfit,
			profitable,
		}
	}

	return {
		web3,
		currentAddress,
		shortAddress,
		dexFactory,
		networkId,
		initializeWeb3,
		connect,
		loadContracts,
		calcProfits,
	}
})
