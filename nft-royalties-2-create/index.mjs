import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const startingBalance = stdlib.parseCurrency(100);

const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);
const accClaire = await stdlib.newTestAccount(startingBalance);

const owners = [
  ['Alice',  accAlice],
  ['Bob',    accBob  ],
  ['Claire', accClaire],
];

const getOwner = (who) => {
  return owners.find(([, account]) => stdlib.addressEq(who, account));
}
const getRandomNewOwner = (who) => {
  const others = owners.filter((owner) => owner[0] !== who);
  return others[Math.floor(Math.random() * others.length)];
}
const stopTrading = (who) => {
  console.log(`${who} keeps the NFT.`);
  process.exit(0);
}

const ctcAlice = accAlice.contract(backend);

let trades = 3;
const makeOwner = (who, acc) => {
  const ctc = acc.contract(backend, ctcAlice.getInfo());
  return ctc.p.Owner({
    newOwner: async () => {
      if (trades == 0) {
        stopTrading(who)
      }
      trades--;
      const owner = getRandomNewOwner(who);
      console.log(`${who} sends the NFT to ${owner[0]}.`);
      return owner[1];
    },
    showOwner: (id, acc) => {
      const owner = getOwner(acc);
      if (owner[0] === who) {
        console.log(`${who} sees that they own the NFT #${id}.`);
      } else {
        console.log(`${who} sees that ${owner[0]} owns the NFT #${id}.`);
      }
    }
  });
};

await Promise.all([
  ctcAlice.p.Creator({
    getId: () => {
      const nft = stdlib.randomUInt();
      console.log(`Alice mints the NFT #${nft}.`);
      return nft; 
    }
  }),
  makeOwner(...owners[0]),
  makeOwner(...owners[1]),
  makeOwner(...owners[2]),
]);