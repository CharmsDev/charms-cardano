import { Core } from "@evolution-sdk/evolution";
import { makePlutusV3Script } from "@evolution-sdk/evolution/sdk/Script";

const script =
  "5878010100229800aba2aba1aab9eaab9dab9a9bae002488888966002646464b30013370e900218031baa0018994c0040166eb8c024c028c028c028c028c028c028c028c028c028c028c028c020dd518048024dd71804801aed46010600e6ea80062c8028c01cc020004c01c004c010dd5003c52689b2b200401";
const params = [
  Core.Bytes.fromHex(
    "DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659"
  ),
];

const parameterizedScriptHex = Core.UPLC.applyParamsToScript(script, params);

console.log("Parameterized Script.");
console.log("Compiled Code: ", parameterizedScriptHex);

// Create PlutusV3 script directly from the hex
const scriptBytes = Core.Bytes.fromHex(parameterizedScriptHex);
const parameterizedScript = {
  _tag: "PlutusV3" as const,
  bytes: scriptBytes,
};

console.log("Script object:", parameterizedScript);
console.log("Script _tag:", parameterizedScript._tag);

console.log(
  "Script Hash: ",
  Core.ScriptHash.fromScript(
    parameterizedScript as unknown as Core.Script.Script
  )
);
