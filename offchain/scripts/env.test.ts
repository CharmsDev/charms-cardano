import { getEnv } from "./env";

test("expect env to load", () => {
  expect(getEnv("BLOCKFROST_URL").startsWith("https://")).toBeTruthy();
});
