<template>
  <div class="d-flex flex-column align-items-center">
    <h1 class="mb-5">Create an NFT</h1>
    <div class="mb-4">
      <h5>Name:</h5>
      <b-input v-model="name" maxlength="256" />
    </div>
    <div class="mb-4">
      <h5>URL:</h5>
      <b-input v-model="url" maxlength="256" />
    </div>
    <img class="nft-img mb-4" :src="url" v-if="url" />
    <div class="mb-5">
      <h5>Royalty:</h5>
      <div class="d-flex align-items-center">
        <b-input-group append="%">
          <b-input type="number" v-model="royalty" min="0" max="100" />
        </b-input-group>
      </div>
    </div>
    <b-button variant="info" @click="create" :disabled="isLoading">
      <b-spinner v-if="isLoading" class="mr-2" small />
      Create
    </b-button>
  </div>
</template>

<script>
import { mapState } from 'vuex';

import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });

import * as backend from '../../build/index.main.mjs';

export default {
  name: 'CreatorView',
  data() {
    return {
      isLoading: false,
      royalty: 10,
      name: '',
      url: '',
    };
  },
  computed: {
    ...mapState({
      account: (state) => state.account,
    }),
  },
  methods: {
    async create() {
      // set loading to false when transactions get aborted
      const fnCatch = () => {
        this.isLoading = false;
        window.removeEventListener('unhandledrejection', fnCatch);
      };
      window.addEventListener('unhandledrejection', fnCatch);

      this.isLoading = true;
      const contract = this.account.contract(backend);
      contract.p.Creator(this);
      await contract.e.Logger.change.next();
      await this.$store.dispatch('setContract', contract);
      this.isLoading = false;
    },
    getId() {
      return reach.randomUInt();
    },
  },
};
</script>

<style>
.nft-img {
  max-height: 200px;
}
</style>
