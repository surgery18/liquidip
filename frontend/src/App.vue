<script setup>
	import Loader from "@/components/Loader.vue"
	import { RouterView } from "vue-router"
</script>

<template>
	<div class="app">
		<loader />
		<RouterView />
	</div>
</template>

<style lang="less" scoped></style>
