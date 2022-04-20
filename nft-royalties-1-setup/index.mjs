import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const startingBalance = stdlib.parseCurrency(100);

const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);
const accClaire = await stdlib.newTestAccount(startingBalance);

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());
const ctcClaire = accClaire.contract(backend, ctcAlice.getInfo());

await Promise.all([
  ctcAlice.p.Creator({
    // implement Alice's interact object as the creator here
  }),
  ctcAlice.p.Owner({
    // implement Alice's interact object as an owner here
  }),
  ctcBob.p.Owner({
    // implement Bob's interact object as an owner here
  }),
  ctcClaire.p.Owner({
    // implement Claire's interact object as an owner here
  }),
]);