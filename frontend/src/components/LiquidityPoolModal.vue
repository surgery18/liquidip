<template>
	<BaseModal :show="show" @close="closeModal">
		<template #title> Create Liquidity Pool </template>

		<div class="form-group">
			<label for="tokenAAddress">Token A Address:</label>
			<input
				type="text"
				class="form-control bg-white text-dark"
				id="tokenAAddress"
				v-model="tokenAAddress"
			/>
		</div>
		<div class="form-group">
			<label for="tokenBAddress">Token B Address:</label>
			<input
				type="text"
				class="form-control bg-white text-dark"
				id="tokenBAddress"
				v-model="tokenBAddress"
			/>
		</div>

		<template #footer>
			<button type="button" class="btn btn-secondary" @click="closeModal">
				Cancel
			</button>
			<button
				type="button"
				class="btn btn-primary"
				@click="createLiquidityPool"
			>
				Create Pool
			</button>
		</template>
	</BaseModal>
</template>

<script>
	import BaseModal from "./BaseModal.vue"

	export default {
		components: {
			BaseModal,
		},
		props: ["show"],
		data() {
			return {
				tokenAAddress: "",
				tokenBAddress: "",
			}
		},
		watch: {
			show(v) {
				if (v) {
					this.tokenAAddress = ""
					this.tokenBAddress = ""
				}
			},
		},
		methods: {
			closeModal() {
				this.$emit("close")
			},
			createLiquidityPool() {
				// Liquidity pool creation logic
				if (this.tokenAAddress === "" || this.tokenBAddress === "") {
					alert("Token addresses cannot be empty")
					return
				}

				this.$emit("createLiquidity", this.tokenAAddress, this.tokenBAddress)
			},
		},
	}
</script>

<style lang="less" scoped></style>
