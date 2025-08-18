import "dotenv/config";
import * as dotenv from "dotenv";
import { writeFileSync } from "fs";
import dotenvParseVariables from "dotenv-parse-variables";

export function getEnv(variable: string): string {
  const value = process.env[variable];
  if (!value) {
    throw Error(
      `Must set ${variable} is a required environment variable. Did you use 'pnpm run .env <task>'?`
    );
  }

  return value;
}

export function updateEnv(config = {}, eol = "\n") {
  let env = dotenv.config({});
  if (env.error) throw env.error;
  if (!!env.parsed) env = dotenvParseVariables(env.parsed);

  const envContents = Object.entries({ ...env, ...config })
    .map(([key, val]) => `${key}=${val}`)
    .join(eol);

  writeFileSync(".env", envContents);
}
