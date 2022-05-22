<template>
  <div id="app" class="d-flex flex-column">
    <navbar />
    <div
      class="d-flex flex-grow-1 flex-column align-items-center p-5"
      :class="{ 'justify-content-center': !view || !account }"
    >
      <b-spinner v-if="isLoading" />
      <template v-else>
        <h3 v-if="!account">Please connect your Wallet!</h3>
        <template v-else-if="!view">
          <b-button variant="info" @click="view = 'creator'" size="lg"
            ><b-icon class="mr-2" icon="plus-circle-fill" />Create</b-button
          >
          <p class="text-muted p-2 mb-5">Create a new NFT.</p>
          <b-button variant="info" @click="view = 'owner'" size="lg"
            ><b-icon class="mr-2" icon="currency-exchange" />Interact</b-button
          >
          <p class="text-muted p-2">Interact with NFTs you own or from others.</p>
        </template>
        <component v-else :is="view" />
      </template>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';

import Navbar from '@/components/Navbar.vue';
import Creator from '@/components/Creator.vue';
import Owner from '@/components/Owner.vue';

export default {
  name: 'App',
  components: {
    navbar: Navbar,
    creator: Creator,
    owner: Owner,
  },
  data() {
    return {
      isLoading: true,
      view: undefined,
    };
  },
  async mounted() {
    this.view = undefined;
    await this.$store.dispatch('refreshAccount');
    this.isLoading = false;
  },
  computed: {
    ...mapState({
      account: (state) => state.account,
      contract: (state) => state.contract,
    }),
  },
  watch: {
    contract: {
      handler(newValue) {
        if (newValue) {
          this.view = 'owner';
        }
      },
      immediate: true,
    },
  },
};
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Architects+Daughter&family=Montserrat&display=swap');

html,
body {
  background-color: #17191c !important;
}

#app {
  font-family: 'Montserrat', sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: var(--light);
  height: 100vh;
}

.btn {
  font-weight: bold !important;
}
</style>
