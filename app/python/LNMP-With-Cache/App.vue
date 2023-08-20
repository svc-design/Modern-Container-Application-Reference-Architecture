<template>
  <div id="app">
    <h1>My App</h1>
    <p>{{ data }}</p>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'App',
  data() {
    return {
      data: null,
    };
  },
  async created() {
    try {
      const response = await axios.get('http://my-app-service');  // replace with your Flask app's service URL
      this.data = response.data;
    } catch (error) {
      console.error(error);
    }
  },
};
</script>
