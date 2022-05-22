import Vue from 'vue';
import Vuex from 'vuex';
import VuexPersistence from 'vuex-persist';

import { loadStdlib } from '@reach-sh/stdlib';
import { ALGO_MyAlgoConnect as MyAlgoConnect } from '@reach-sh/stdlib';

let reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });
reach.setWalletFallback(reach.walletFallback({ providerEnv: 'TestNet', MyAlgoConnect }));

Vue.use(Vuex);

const vuexLocal = new VuexPersistence({
  storage: window.localStorage,
});

const store = new Vuex.Store({
  state: {
    account: undefined,
    balance: undefined,
    contract: undefined,
    contractInfo: undefined,
  },
  actions: {
    async connect(context) {
      const account = await reach.getDefaultAccount();
      const balanceAtomic = await reach.balanceOf(account);
      const balance = reach.formatCurrency(balanceAtomic, 2);
      context.commit('SET_ACCOUNT', account);
      context.commit('SET_BALANCE', balance);
    },
    async disconnect(context) {
      context.commit('SET_ACCOUNT', undefined);
      context.commit('SET_BALANCE', undefined);
    },
    async refreshAccount(context) {
      context.commit('SET_CONTRACT', { contract: undefined, contractInfo: undefined });
      if (context.state.account) {
        const account = await reach.connectAccount(context.state.account.networkAccount);
        const balanceAtomic = await reach.balanceOf(account);
        const balance = reach.formatCurrency(balanceAtomic, 2);
        context.commit('SET_ACCOUNT', account);
        context.commit('SET_BALANCE', balance);
      }
    },
    async setContract(context, contract) {
      const contractInfo = await contract.getInfo();
      context.commit('SET_CONTRACT', { contract, contractInfo });
    },
    async clearContract(context) {
      context.commit('SET_CONTRACT', { contract: undefined, contractInfo: undefined });
    },
  },
  mutations: {
    SET_ACCOUNT(state, account) {
      state.account = account;
    },
    SET_BALANCE(state, balance) {
      state.balance = balance;
    },
    SET_CONTRACT(state, { contract, contractInfo }) {
      state.contract = contract;
      state.contractInfo = contractInfo;
    },
  },
  plugins: [vuexLocal.plugin],
});

export default store;
