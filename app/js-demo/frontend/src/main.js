import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";
import axios from "axios";

const app = createApp(App);

// 注册 Axios 到 Vue 实例
app.config.globalProperties.$axios = axios;

app.use(router).mount("#app");
