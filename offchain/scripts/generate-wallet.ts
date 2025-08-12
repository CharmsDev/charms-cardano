import {
  Blockfrost,
  Lucid,
  Network,
  generatePrivateKey,
} from "@lucid-evolution/lucid";
import { getEnv, updateEnv } from "./env.ts";

const network = getEnv("PUBLIC_CARDANO_NETWORK") as Network;
const url = getEnv("BLOCKFROST_URL");
const projectKey = getEnv("BLOCKFROST_PROJECT_KEY");
const lucid = await Lucid(new Blockfrost(url, projectKey), network);

const privateKey = generatePrivateKey();
lucid.selectWallet.fromPrivateKey(privateKey);

const envUpdate = {
  WALLET_ADDRESS: await lucid.wallet().address(),
  WALLET_PRIVATE_KEY: privateKey,
};
updateEnv(envUpdate);
