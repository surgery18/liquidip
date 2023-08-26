<template>
	<nav class="navbar navbar-expand-lg navbar-light bg-light shadow-sm">
		<div class="container">
			<!-- Left side: Project name and logo -->
			<router-link class="navbar-brand text-dark" to="/">
				<img src="../assets/logo.png" alt="LiquiDip Logo" class="logo-img" />
				LiquiDip
			</router-link>

			<!-- Middle: Page routes -->
			<nav-routes />

			<!-- Right side: User wallet address/connect button -->
			<div class="navbar-text">
				<connect-wallet @contractsLoaded="contractsLoaded" />
			</div>
		</div>
	</nav>
</template>

<script>
	import ConnectWallet from "./ConnectWallet.vue"
	import NavRoutes from "./NavRoutes.vue"
	export default {
		name: "NavBar",
		components: { ConnectWallet, NavRoutes },
		methods: {
			contractsLoaded() {
				this.$emit("contractsLoaded")
			},
		},
	}
</script>

<style scoped>
	/* Optional: Add some padding to the navbar for a spacious feel */
	.navbar {
		padding: 0.5rem 1rem;
	}

	/* Style the logo image */
	.logo-img {
		height: 80px; /* adjust as needed */
		margin-right: 10px; /* spacing between logo and brand name */
		vertical-align: middle; /* aligns the logo with the text */
	}

	.navbar-brand {
		font-size: 2em;
	}
</style>
