<template>
	<div v-if="!web3.currentAddress" class="wallet-prompt">
		<h3>Please Connect Your Wallet</h3>
		<button @click="connect">Connect</button>
	</div>
</template>

<script>
	import { useWeb3Store } from "@/stores/web3" // Assuming you're using a store for web3

	export default {
		name: "WalletConnectPrompt",
		setup() {
			const web3 = useWeb3Store()
			return {
				web3,
			}
		},
		methods: {
			async connect() {
				await this.web3.connect()
				this.$emit("connected")
			},
		},
	}
</script>

<style scoped>
	.wallet-prompt {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 100vh;
		background-color: rgba(0, 0, 0, 0.7);
		color: white;
		font-size: 1.5em;
	}

	button {
		margin-top: 20px;
		padding: 10px 20px;
		font-size: 1em;
		cursor: pointer;
	}
</style>
