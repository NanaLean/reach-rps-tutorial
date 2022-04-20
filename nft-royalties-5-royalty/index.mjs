import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const startingBalance = stdlib.parseCurrency(100);

const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);
const accClaire = await stdlib.newTestAccount(startingBalance);
const accEve = await stdlib.newTestAccount(startingBalance);

const owners = [
  ['Alice', accAlice],
  ['Bob', accBob],
  ['Claire', accClaire],
];

const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));

const getOwner = (who) => {
  return owners.find(([, account]) => stdlib.addressEq(who, account));
}
const getRandomNewOwner = (who) => {
  const others = owners.filter((owner) => owner[0] !== who);
  return others[Math.floor(Math.random() * others.length)];
}
const stopTrading = async (who) => {
  console.log(`${who} keeps the NFT.`);

  await Promise.all(owners.map(async ([name, acc]) => {
    const balance = await getBalance(acc);
    console.log(`${name}'s balance is ${balance}`);
  }));

  process.exit(0);
}

const ctcAlice = accAlice.contract(backend);
const ctcEve = accEve.contract(backend, ctcAlice.getInfo());

let trades = 3;
const makeOwner = (who, acc) => {
  const ctc = acc.contract(backend, ctcAlice.getInfo());
  return ctc.p.Owner({
    newOwner: async () => {
      await externalViewer();
      if (trades == 0) {
        await stopTrading(who);
      }
      trades--;
      const owner = getRandomNewOwner(who);
      console.log(`${who} sends the NFT to ${owner[0]}.`);
      return owner[1];
    },
    buy: (price) => {
      console.log(`${who} buys the NFT for ${fmt(price)}.`)
    },
  });
};
const makeSeller = (who, acc) => {
  const ctc = acc.contract(backend, ctcAlice.getInfo());
  return ctc.p.Seller({
    salePrice: async () => {
      await externalViewer();
      if (trades == 0) {
        await stopTrading(who);
      }
      trades--;
      const price = stdlib.parseCurrency(10);
      console.log(`${who} is setting up the NFT for sale for ${fmt(price)}.`);
      return price;
    }
  });
};
const externalViewer = async () => {
  const [id, owner] = await Promise.all([await ctcEve.v.NFT.id(), await ctcEve.v.NFT.owner()]);
  console.log(`Eve sees that ${getOwner(owner[1])[0]} owns the NFT #${id[1]}.`);
};

await Promise.all([
  ctcAlice.p.Creator({
    getId: () => {
      const nft = stdlib.randomUInt();
      console.log(`Alice mints the NFT #${nft}.`);
      return nft;
    },
    royalty: 20,
  }),
  makeOwner(...owners[0]),
  makeOwner(...owners[1]),
  makeSeller(...owners[2]),
]);