<template>
	<div>
		<!-- Connect Wallet Button -->
		<button
			v-if="!store.currentAddress"
			class="btn btn-lg btn-primary my-4"
			@click="store.connect"
		>
			Connect Wallet
		</button>
		<p v-if="store.currentAddress" class="text-success my-2">
			Connected: {{ store.shortAddress }}
		</p>
	</div>
</template>

<script>
	import { useWeb3Store } from "@/stores/web3"
	// import { mapState } from "pinia"

	export default {
		data() {
			return {
				userAddress: null,
			}
		},
		setup() {
			const store = useWeb3Store()
			return { store }
		},
		async created() {
			// console.log("Connect button created")
			try {
				await this.store.initializeWeb3()
				await this.store.loadContracts()
				this.$emit("contractsLoaded")
			} catch (e) {}
		},
	}
</script>

<style></style>
