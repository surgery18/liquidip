<template>
	<ul class="navbar-nav mr-auto">
		<li class="nav-item" v-for="item in gridItems" :key="item.title">
			<router-link
				:to="item.route"
				class="nav-link text-dark"
				v-text="item.title"
				exact
			></router-link>
		</li>
	</ul>
</template>

<script>
	export default {
		data() {
			return {
				gridItems: [
					{ title: "Dexes", route: "/dex-management" },
					{ title: "Arbitrage", route: "/arbitrage" },
				],
			}
		},
	}
</script>

<style scoped>
	/* Enhance hover effect for navigation links */
	.nav-link:hover {
		color: rgba(0, 0, 0, 0.7) !important; /* Slight fade for hover */
	}

	.router-link-active {
		color: red !important;
	}
</style>
