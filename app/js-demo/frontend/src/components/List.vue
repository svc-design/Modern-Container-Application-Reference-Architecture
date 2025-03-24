<template>
  <div>
    <h2>List Component</h2>
    <button @click="fetchList">Fetch List</button>
    <div v-if="loading">Loading...</div>
    <ul v-if="userList.length > 0">
      <li v-for="user in userList" :key="user.id">{{ user.name }}</li>
    </ul>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'UserList', // Change the component name to a multi-word name
  data() {
    return {
      loading: false,
      userList: []
    };
  },
  methods: {
    fetchList() {
      this.loading = true;

      axios.get('/api/list')
        .then(response => {
          this.userList = response.data;
        })
        .catch(error => {
          console.error('Error fetching list:', error);
        })
        .finally(() => {
          this.loading = false;
        });
    }
  }
};
</script>

<style scoped>
/* Component-specific styles here */
</style>
