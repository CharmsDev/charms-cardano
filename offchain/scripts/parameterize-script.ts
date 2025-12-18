import {
  applyParamsToScript,
  validatorToScriptHash,
  Script,
} from "@lucid-evolution/lucid";

const script =
  "5878010100229800aba2aba1aab9eaab9dab9a9bae002488888966002646464b30013370e900218031baa0018994c0040166eb8c024c028c028c028c028c028c028c028c028c028c028c028c020dd518048024dd71804801aed46010600e6ea80062c8028c01cc020004c01c004c010dd5003c52689b2b200401";
const params = [
  "DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659",
];

const parameterizedScript = applyParamsToScript(script, params);

console.log("Parameterized Script.");
console.log("Compiled Code: ", parameterizedScript);
console.log(
  "Script Hash: ",
  validatorToScriptHash({
    type: "PlutusV3",
    script: parameterizedScript,
  } as Script)
);
