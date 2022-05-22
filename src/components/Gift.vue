<template>
  <div>
    <div class="mb-4">
      <h5>Address:</h5>
      <b-input v-model="address" />
    </div>
    <b-button variant="info" @click="gift" :disabled="isLoading">
      <b-spinner v-if="isLoading" class="mr-2" small />
      <b-icon v-else class="mr-2" icon="gift" />
      Gift
    </b-button>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import ownerInterface from '@/utils/ownerInterface';

export default {
  name: 'GiftView',
  data() {
    return {
      isLoading: false,
      address: '',
    };
  },
  computed: {
    ...mapState({
      contract: (state) => state.contract,
    }),
  },
  methods: {
    async gift() {
      this.isLoading = true;
      this.contract.p.Owner(Object.assign(ownerInterface, this));
    },
    transferOption() {
      return 0;
    },
    newOwner() {
      return this.address;
    },
  },
};
</script>

<style></style>
