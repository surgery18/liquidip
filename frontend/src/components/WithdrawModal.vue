<template>
	<BaseModal :show="show" @close="closeModal">
		<template #title>
			<h5 class="modal-title">Withdraw Liquidity</h5>
		</template>

		<!-- Pool Address Display -->
		<div class="mb-3">
			<label for="poolAddress" class="form-label">Pool Address:</label>
			<input
				type="text"
				id="poolAddress"
				class="form-control bg-white text-dark"
				:value="selectedPool.contractAddress"
				readonly
			/>
		</div>

		<!-- LP Tokens Display -->
		<div class="mb-3">
			<label class="form-label">Your LP Tokens:</label>
			<span class="mx-2">{{ lpTokens }}</span>
		</div>

		<!-- LP Tokens Withdrawal Input -->
		<div class="mb-3">
			<label for="withdrawAmount" class="form-label">Amount to Withdraw:</label>
			<input
				type="number"
				id="withdrawAmount"
				class="form-control bg-white text-dark"
				v-model="withdrawAmount"
			/>
		</div>

		<template #footer>
			<!-- Cancel Button -->
			<button type="button" class="btn btn-secondary" @click="closeModal">
				Cancel
			</button>

			<!-- Withdraw Button -->
			<button type="button" class="btn btn-primary" @click="confirmWithdrawal">
				Withdraw
			</button>
		</template>
	</BaseModal>
</template>

<script>
	import BaseModal from "./BaseModal.vue"
	import { useWeb3Store } from "@/stores/web3"
	import IERC20 from "../../../build/contracts/IERC20.json"

	export default {
		components: { BaseModal },
		props: ["show", "selectedPool"],
		data() {
			return {
				withdrawAmount: "",
				lpTokens: "",
			}
		},
		setup() {
			const web3Store = useWeb3Store()
			return { web3Store }
		},
		watch: {
			show(v) {
				if (v) {
					this.fetchBal()
				} else {
					this.lpTokens = ""
					this.withdrawAmount = ""
				}
			},
		},
		methods: {
			async fetchBal() {
				//fetch balance
				const web3 = this.web3Store.web3
				const currentAddress = this.web3Store.currentAddress
				const token = new web3.eth.Contract(
					IERC20.abi,
					this.selectedPool.contractAddress
				)
				const bal = (await token.methods.balanceOf(currentAddress).call()) ?? 0
				this.lpTokens = web3.utils.fromWei(bal, "ether")
			},
			closeModal() {
				this.$emit("close")
			},
			confirmWithdrawal() {
				// Logic to handle withdrawal goes here
				if (
					isNaN(this.withdrawAmount) ||
					this.withdrawAmount <= 0 ||
					this.withdrawAmount > this.lpTokens
				) {
					// Handle error: invalid withdrawal amount
					alert("Invalid withdrawal amount")
					return
				}
				this.$emit("confirmWithdraw", this.withdrawAmount)
			},
		},
	}
</script>
