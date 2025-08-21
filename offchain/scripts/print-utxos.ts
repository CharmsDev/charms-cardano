import { Lucid, Blockfrost, Network } from "@lucid-evolution/lucid";

import { getEnv } from "./env.ts";

const network = getEnv("PUBLIC_CARDANO_NETWORK");
const address = getEnv("WALLET_ADDRESS");
const blockfrostUrl = getEnv(`BLOCKFROST_URL`);
const blockfrostKey = getEnv(`BLOCKFROST_PROJECT_KEY`);

console.log(address);

const blockfrost = new Blockfrost(blockfrostUrl, blockfrostKey);
const lucid = await Lucid(blockfrost, network as Network);
const utxos = await lucid.utxosAt(address);

console.log(utxos);
