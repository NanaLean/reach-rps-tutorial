<template>
  <div v-if="!ctcInfo">
    <h3>Creator</h3>
    <br />
    <h3>Set royalty:</h3>
    <input type="number" v-model="royalty" min="0" max="100" />
    <button @click="create">Create</button>
  </div>
  <owner v-else :initialCtc="ctcInfo" :acc="acc"/>
</template>

<script>
import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });

import * as backend from '../../build/index.main.mjs';
import Owner from '@/components/Owner.vue'

export default {
  name: 'CreatorView',
  props: {
    acc: {
      type: Object,
      required: true,
    }
  },
  components: {
    'owner': Owner,
  },
  data() {
    return {
      ctc: undefined,
      ctcInfo: undefined,
      royalty: 1,
    }
  },
  methods: {
    async create() {
      this.ctc = this.acc.contract(backend);
      backend.Creator(this.ctc, this);
      await this.ctc.e.Logger.change.next();
      this.ctcInfo = await this.ctc.getInfo();
    },
    getId() {
      return reach.randomUInt();
    }
  }
}
</script>

<style>
</style>
