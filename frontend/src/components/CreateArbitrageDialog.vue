<!-- CreateArbitrageDialog.vue -->
<template>
	<BaseModal :show="show" @close="closeModal">
		<template #title> Create Arbitrage </template>

		<div class="modal-body">
			<!-- DEX Selection -->
			<h5>Select Two Dexes</h5>
			<!-- <div class="d-flex flex-row justify-content-around my-3"></div> -->
			<div>
				<label>Select DEX A:</label>
				<select v-model="selectedDexA">
					<option v-for="(dex, id) in dexes" :key="id" :value="dex">
						{{ dex.dex }}
					</option>
				</select>
			</div>
			<div class="mt-2">
				<label>Select DEX B:</label>
				<select v-model="selectedDexB">
					<option v-for="(dex, id) in dexes" :key="id" :value="dex">
						{{ dex.dex }}
					</option>
				</select>
			</div>

			<!-- Token Selection from DEX A -->
			<h5 class="my-5">Select Two Tokens from Dex A</h5>
			<div class="d-flex flex-row justify-content-around">
				<button
					@click="openTokenModal('token0')"
					class="btn btn-lg btn-primary"
					v-text="selectedToken0.name"
					:disabled="tokens.length === 0"
				></button>

				<button
					@click="openTokenModal('token1')"
					class="btn btn-lg btn-primary"
					v-text="selectedToken1.name"
					:disabled="tokens.length === 0"
				></button>
			</div>
		</div>

		<template #footer>
			<button class="btn btn-secondary" @click="closeModal">Cancel</button>
			<button
				class="btn btn-success"
				@click="createArbitrage"
				:disabled="!canCreate"
			>
				Create
			</button>
		</template>
	</BaseModal>
</template>

<script>
	import BaseModal from "@/components/BaseModal.vue"
	import { useWeb3Store } from "@/stores/web3"
	import { startLoading, stopLoading } from "@/utils/eventbus"
	import ArbitrageFactory from "../../../build/contracts/ArbitrageFactory.json"

	export default {
		components: { BaseModal },
		props: ["show", "tokens"],
		data() {
			return {
				dexes: [], // List of DEXes, to be fetched from backend or contract
				selectedDexA: null,
				selectedDexB: null,
				selectedToken0: {
					name: "Select Token0",
				},
				selectedToken1: { name: "Select Token1" },
				curTokenSelection: "",
				canCreate: false,
			}
		},
		setup() {
			return { web3: useWeb3Store(), startLoading, stopLoading }
		},
		watch: {
			show(v) {
				if (v && !this.curTokenSelection) {
					this.getDexes()
				}
			},

			selectedToken0: {
				handler() {
					this.updateCanCreate()
				},
				deep: true,
			},
			selectedToken1: {
				handler() {
					this.updateCanCreate()
				},
				deep: true,
			},
			selectedDexA: {
				handler() {
					//fetch tokens
					this.$emit("onSelectDexA", this.selectedDexA)
					this.updateCanCreate()
				},
				deep: true,
			},
			selectedDexB: {
				handler() {
					this.updateCanCreate()
				},
				deep: true,
			},
		},
		methods: {
			updateCanCreate() {
				this.canCreate =
					this.selectedToken0?.symbol &&
					this.selectedToken1?.symbol &&
					this.selectedDexA?.dex &&
					this.selectedDexB?.dex
			},
			async getDexes() {
				try {
					const count = await this.web3.dexFactory.methods.getDEXCount().call()
					// console.log(count)
					this.dexes = []
					if (count > 0) {
						for (let i = 0; i < count; i++) {
							const dex = await this.web3.dexFactory.methods
								.getDEXDetails(i)
								.call()
							this.dexes.push(dex)
						}
					}
					// console.log(this.dexes)
				} catch (e) {
					console.log(e)
				}
			},
			closeModal() {
				this.selectedDexA = null
				this.selectedDexB = null
				this.selectedToken0 = {
					name: "Select Token0",
				}
				this.selectedToken1 = { name: "Select Token1" }
				this.curTokenSelection = ""
				this.canCreate = false
				this.$emit("close")
			},
			openTokenModal(tokenType) {
				// Logic to open the token modal for token selection
				this.curTokenSelection = tokenType
				this.$emit("hide")
			},
			selectToken(token) {
				console.log("TOKEN SELECTED", token)
				if (this.curTokenSelection === "token0") {
					this.selectedToken0 = token
				} else {
					this.selectedToken1 = token
				}
			},
			async createArbitrage() {
				// Logic to create the arbitrage
				if (this.selectedDexA.dex === this.selectedDexB.dex) {
					alert("Error: Same DEX selected twice")
					return
				}
				if (this.selectedToken0.symbol === this.selectedToken1.symbol) {
					alert("Error: Same token selected twice")
					return
				}
				// Continue with the rest of the logic to create the arbitrage
				const web3 = this.web3.web3
				startLoading()
				try {
					const arbf = new web3.eth.Contract(
						ArbitrageFactory.abi,
						ArbitrageFactory.networks[this.web3.networkId].address
					)
					const tx = await arbf.methods
						.createArbitrage(
							this.selectedDexA.dex,
							this.selectedDexB.dex,
							this.selectedDexA.flashLoanProvider,
							this.selectedToken0.address,
							this.selectedToken1.address
						)
						.send({ from: this.web3.currentAddress })
				} catch (e) {
					console.log(e)
				}
				stopLoading()
				this.closeModal()
			},
		},
	}
</script>
