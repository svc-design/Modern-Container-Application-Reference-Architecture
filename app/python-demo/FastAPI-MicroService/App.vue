<template>
  <div id="app">
    <h1>My App</h1>
    <p>{{ data }}</p>
    <button @click="produce">Produce Message</button>
    <button @click="consume">Consume Message</button>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'App',
  data() {
    return {
      data: null,
      message: { key: "value" },  // replace this with the actual message you want to produce
    };
  },
  async created() {
    try {
      const response = await axios.get('http://my-app-service');
      this.data = response.data;
    } catch (error) {
      console.error(error);
    }
  },
  methods: {
    async produce() {
      try {
        await axios.post('http://my-app-service/produce', this.message);
      } catch (error) {
        console.error(error);
      }
    },
    async consume() {
      try {
        const response = await axios.get('http://my-app-service/consume');
        this.data = response.data;
      } catch (error) {
        console.error(error);
      }
    },
  },
};
</script>
