import { loadStdlib, ask } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const isCreator = await ask.ask(
  `Do you want to create a new NFT?`,
  ask.yesno
);

let acc = null;
const createAcc = await ask.ask(
  `Would you like to create an account? (only possible on devnet)`,
  ask.yesno
);
if (createAcc) {
  acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
} else {
  const secret = await ask.ask(
    `What is your account secret?`,
    (x => x)
  );
  acc = await stdlib.newAccountFromSecret(secret);
}

let ctc = null;
if (isCreator) {
  ctc = acc.contract(backend);
  ctc.getInfo().then((info) => {
    console.log(`The contract is deployed as:\n${JSON.stringify(info)}`); });
} else {
  const info = await ask.ask(
    `Please paste the contract information:`,
    JSON.parse
  );
  ctc = acc.contract(backend, info);
}

const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async () => fmt(await stdlib.balanceOf(acc));

const before = await getBalance();
console.log(`\nYour address is ${stdlib.formatAddress(acc)}.\nYour balance is ${before}.\n`);

let interact = { ...stdlib.hasRandom };

const checkOwner = async () => {
  const [id, owner] = await Promise.all([await ctc.v.NFT.id(), await ctc.v.NFT.owner()])
  const isOwner = stdlib.addressEq(owner[1], acc);
  if (isOwner) {
    console.log(`You own the NFT #${id[1]}.`);
  } else {
    console.log(`${stdlib.formatAddress(owner[1])} owns the NFT #${id[1]}.`);
  }
  const after = await getBalance();
  console.log(`Your balance is ${after}.\n`);
  return isOwner;
};
const newOnwerListener = async () => {
  await ctc.e.Logger.change.next();
  await checkOwner();
  newOnwerListener();
}
newOnwerListener();

if (isCreator) {
  interact.getId = () => {
    const nft = stdlib.randomUInt();
    console.log(`You mint the NFT #${nft}.`);
    return nft;
  };
  const royalty = await ask.ask(
    `How much royalty do you want to receive for your NFT (in %)?`,
    (x) => parseInt(x)
  );
  interact.royalty = royalty;
}

interact.transferOption = async () => {
  const option = await ask.ask(
    'What do you want to do with the NFT? [Gift / Sell / Auction / Keep]',
    (x) => x.toLowerCase().startsWith('g') ? 0 : 
           x.toLowerCase().startsWith('s') ? 1 :
           x.toLowerCase().startsWith('a') ? 2 :
                                             3
  );
  if (option == 3) {
    process.exit(0);
  }
  return option;
};

interact.newOwner = async () => {
  const newOwner = await ask.ask('Who do you want to gift the NFT to?');
  return newOwner;
}

interact.getAuctionProps = async () => {
  const startingBid = await ask.ask('What should be the starting bid?');
  const timeout = await ask.ask('How long should the auction run?');
  return { startingBid: stdlib.parseCurrency(startingBid), timeout };
}

interact.getBid = async (currentBid) => {
  const bid = await ask.ask(`The current bid is ${fmt(currentBid)}. How much do you want to bid?`);
  return ['Some', stdlib.parseCurrency(bid)];
}

interact.salePrice = async () => {
  const salePrice = await ask.ask('For how much do you want to sell the NFT?')
  return stdlib.parseCurrency(salePrice);
}

interact.buy = async (salePrice) => {
  const isBuy = await ask.ask(`The NFT is up for sale for ${fmt(salePrice)}. Do you want to buy it?`, ask.yesno);
  if (!isBuy) {
    process.exit(0);
  }
  return;
}

if (isCreator) {
  ctc.p.Creator(interact);
}
ctc.p.Owner(interact);