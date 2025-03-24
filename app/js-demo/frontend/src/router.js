import { createRouter, createWebHistory } from "vue-router";
import List from "./components/List.vue";

const routes = [
  { path: "/", component: List }
  // Add more routes as needed
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

export default router;
