<template>
  <div class="header">
    <button v-if="!acc" @click="connect">Connect</button>
    <template v-else>
      <div class="balance">{{ bal }}</div>
      <div class="account">{{ acc ? acc.networkAccount.addr : '' }}</div>
    </template>
  </div>
  <div class="content">
    <h1>Transferable Royalty NFTs</h1>
    <br />
    <template v-if="acc && !view">
      <h3>Select a role:</h3>
      <br />
      <button @click="view = 'creator'">Creator</button>
      <p>Create an NFT.</p>
      <br />
      <button @click="view = 'owner'">Owner</button>
      <p>Interact with NFTs you own or buy NFTs from others.</p>
    </template>
    <h3 v-else-if="!acc">Please connect your Wallet!</h3>
    <component v-else :is="view" :acc="acc" />
  </div>
</template>

<script>
import { loadStdlib } from '@reach-sh/stdlib';
import { ALGO_MyAlgoConnect as MyAlgoConnect } from '@reach-sh/stdlib';
import Creator from '@/components/Creator.vue'
import Owner from '@/components/Owner.vue'

const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });
reach.setWalletFallback(reach.walletFallback({ providerEnv: 'TestNet', MyAlgoConnect }));

export default {
  name: 'App',
  components: {
    'creator': Creator,
    'owner': Owner,
  },
  data() {
    return {
      acc: undefined,
      bal: undefined,
      view: undefined,
    }
  },
  methods: {
    async connect() {
      const acc = await reach.getDefaultAccount();
      const balAtomic = await reach.balanceOf(acc);
      const bal = reach.formatCurrency(balAtomic, 4);
      this.acc = acc;
      this.bal = bal;
    },
  }
}
</script>

<style>
@import './assets/base.css';

#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.header {
  height: 40px;
  background: rgba(0, 0, 0, 0.2);
  padding: 8px 16px;
  display: flex;
  justify-content: flex-end;
}

.content {
  flex: 1;
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
}

.account {
  width: 60px;
  text-overflow: ellipsis;
  overflow: hidden;
}

.account, .balance {
  margin-right: 16px;
}
</style>
