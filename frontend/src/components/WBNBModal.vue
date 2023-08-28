<template>
	<BaseModal :show="show" @close="closeModal">
		<template #title> WBNB Management </template>

		<div class="modal-body">
			<!-- Balance Display -->
			<div class="balance-section">
				<p>Your WBNB Balance: {{ balance }}</p>
			</div>

			<!-- Deposit Section -->
			<div class="action-section">
				<label for="depositAmount">Deposit WBNB:</label>
				<input type="number" id="depositAmount" v-model="depositAmount" />
				<button class="btn btn-outline-light" @click="handleDeposit">
					Deposit
				</button>
			</div>

			<!-- Withdraw Section -->
			<div class="action-section">
				<label for="withdrawAmount">Withdraw WBNB:</label>
				<input type="number" id="withdrawAmount" v-model="withdrawAmount" />
				<button class="btn btn-outline-light" @click="handleWithdraw">
					Withdraw
				</button>
			</div>
		</div>

		<template #footer>
			<button type="button" class="btn btn-secondary" @click="closeModal">
				Close
			</button>
		</template>
	</BaseModal>
</template>

<script>
	import BaseModal from "./BaseModal.vue"
	// Import other necessary utilities or contracts
	import { useWeb3Store } from "@/stores/web3"
	import WBNB from "../../../build/contracts/WBNB.json"
	import { startLoading, stopLoading } from "@/utils/eventbus"

	export default {
		components: {
			BaseModal,
		},
		props: ["show"],
		data() {
			return {
				balance: "0.00", // Placeholder balance value, fetch actual value in mounted or a watcher
				depositAmount: "",
				withdrawAmount: "",
			}
		},
		setup() {
			const web3 = useWeb3Store()
			return { web3, startLoading, stopLoading }
		},
		watch: {
			async show(v) {
				if (v) {
					if (!this.web3.currentAddress) alert("CONNECT WALLET")
					await this.fetchBalance()
				}
			},
		},
		methods: {
			closeModal() {
				this.$emit("close")
			},
			async handleDeposit() {
				if (!(+this.depositAmount > 0)) {
					alert("Deposit amount needs to be greater than 0")
					return
				}
				// Logic to handle depositing WBNB
				// After depositing, you might want to update the balance display
				const web3 = this.web3.web3
				if (!this.web3.currentAddress) {
					alert("Connect Wallet to use")
					return
				}
				startLoading()
				const token = new web3.eth.Contract(
					WBNB.abi,
					WBNB.networks[this.web3.networkId].address
				)
				try {
					const tx = await token.methods.deposit().send({
						value: web3.utils.toWei(this.depositAmount.toString(), "ether"),
						from: this.web3.currentAddress,
					})
					console.log(tx)
				} catch (e) {
					console.log(e)
				}
				stopLoading()
				await this.fetchBalance()
				this.depositAmount = ""
			},
			async handleWithdraw() {
				if (!(+this.withdrawAmount > 0)) {
					alert("Deposit amount needs to be greater than 0")
					return
				}
				// Logic to handle withdrawing WBNB
				// After withdrawing, you might want to update the balance display
				const web3 = this.web3.web3
				if (!this.web3.currentAddress) {
					alert("Connect Wallet to use")
					return
				}
				startLoading()
				const token = new web3.eth.Contract(
					WBNB.abi,
					WBNB.networks[this.web3.networkId].address
				)
				try {
					const tx = await token.methods
						.withdraw(web3.utils.toWei(this.withdrawAmount.toString(), "ether"))
						.send({
							from: this.web3.currentAddress,
						})
					console.log(tx)
				} catch (e) {
					console.log(e)
				}
				stopLoading()
				await this.fetchBalance()
				this.withdrawAmount = ""
			},
			async fetchBalance() {
				// Replace with your logic to fetch WBNB balance
				// This is just a placeholder.
				const web3 = this.web3.web3
				if (!this.web3.currentAddress) {
					this.balance = " -CONNECT WALLET-"
					return
				}
				const token = new web3.eth.Contract(
					WBNB.abi,
					WBNB.networks[this.web3.networkId].address
				)
				const balWei = await token.methods
					.balanceOf(this.web3.currentAddress)
					.call()
				const bal = web3.utils.fromWei(balWei, "ether")
				// this.balance = (+bal).toFixed(2)
				this.balance = bal
			},
		},
	}
</script>

<style scoped>
	.balance-section {
		margin-bottom: 20px;
	}

	.action-section {
		margin-bottom: 15px;
	}

	.action-section button {
		margin-left: 10px;
	}
</style>
