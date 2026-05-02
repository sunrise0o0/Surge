global.$arguments = {
  provider: "TAG",
  flag: true,
  one: true,
  keep: "GPT+NF+IPLC",
  blockquic: "off",
  clear: true,
};

const { operator } = require("../Module/Spec/Sub-Store/Moore/Node-Rename.js");

function assert(condition, message) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

const input = [
  { name: "香港 IPLC 01 GPT", type: "ss" },
  { name: "HK IPLC 02 Netflix", type: "ss" },
  { name: "日本 东京 2x", type: "trojan" },
  { name: "United States Los Angeles 原生", type: "vmess" },
  { name: "剩余流量 100G", type: "ss" },
];

const output = operator(input);
const names = output.map((proxy) => proxy.name);

assert(output.length === 4, "traffic notice node is filtered");
assert(names.includes("TAG 🇭🇰 香港 IPLC GPT"), "Chinese Hong Kong node keeps provider, flag, IPLC, and GPT");
assert(names.includes("TAG 🇭🇰 香港 IPLC NF"), "English Hong Kong node keeps provider, flag, IPLC, and NF");
assert(names.includes("TAG 🇯🇵 日本 2x"), "Japan node keeps provider, flag, and rate");
assert(names.includes("TAG 🇺🇸 美国 原生"), "United States node keeps provider, flag, and native tag");
assert(output.every((proxy) => proxy["block-quic"] === "off"), "block-quic is set");

console.log("Sub-Store node rename tests passed.");
