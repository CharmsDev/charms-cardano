import {
  Core,
  BlockfrostConfig,
  createClient,
  NetworkId,
} from "@evolution-sdk/evolution";

import { getEnv } from "./env.ts";

const network = getEnv("PUBLIC_CARDANO_NETWORK") as NetworkId;
const address = getEnv("WALLET_ADDRESS");
const blockfrostUrl = getEnv(`BLOCKFROST_URL`);
const blockfrostKey = getEnv(`BLOCKFROST_PROJECT_KEY`);

console.log(address);

const blockfrost: BlockfrostConfig = {
  type: "blockfrost",
  baseUrl: blockfrostUrl,
  projectId: blockfrostKey,
};
const lucid = createClient({
  network,
  provider: blockfrost,
  wallet: {
    type: "read-only",
    address: address,
  },
});
const utxos = await lucid.getWalletUtxos();

console.log(utxos);
