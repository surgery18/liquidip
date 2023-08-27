import { createRouter, createWebHistory } from "vue-router"
import HomeView from "@/views/HomeView.vue"
import DexManagementView from "@/views/DexManagementView.vue"
import ArbitrageView from "@/views/ArbitrageView.vue"

const router = createRouter({
	history: createWebHistory(import.meta.env.BASE_URL),
	routes: [
		{
			path: "/",
			name: "home",
			component: HomeView,
		},
		{
			path: "/dex-management",
			name: "dex-management",
			component: DexManagementView,
		},
		{
			path: "/arbitrage",
			name: "arbitrage",
			component: ArbitrageView,
		},
	],
})

export default router
