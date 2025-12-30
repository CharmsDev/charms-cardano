import {
  BlockfrostConfig,
  Core,
  createClient,
  NetworkId,
  SeedWalletConfig,
} from "@evolution-sdk/evolution";
import { getEnv, updateEnv } from "./env.ts";

const network = getEnv("PUBLIC_CARDANO_NETWORK") as NetworkId;
const blockfrostUrl = getEnv("BLOCKFROST_URL");
const blockfrostKey = getEnv("BLOCKFROST_PROJECT_KEY");

const mnemonic = Core.PrivateKey.generateMnemonic();

const blockfrost: BlockfrostConfig = {
  type: "blockfrost",
  baseUrl: blockfrostUrl,
  projectId: blockfrostKey,
};

const wallet: SeedWalletConfig = {
  type: "seed",
  mnemonic: mnemonic,
};

const lucid = createClient({
  network,
  provider: blockfrost,
  wallet,
});

const envUpdate = {
  WALLET_ADDRESS: Core.Address.toBech32(await lucid.address()),
  WALLET_MNEMONIC: mnemonic,
};
updateEnv(envUpdate);
