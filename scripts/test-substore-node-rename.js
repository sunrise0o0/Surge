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
  { name: "Traffic: 137.51 GB | 150 GB", type: "trojan", _subName: "huayun", _subDisplayName: "花云" },
  { name: "Expire: 2026-05-11", type: "trojan", _subName: "huayun", _subDisplayName: "花云" },
  { name: "剩余流量：4.13 TB", type: "vless", _subName: "lx", _subDisplayName: "良心-共享" },
  { name: "套餐到期：长期有效", type: "vless", _subName: "lx", _subDisplayName: "良心-共享" },
  { name: "🇭🇰 香港-广东专线 BGP 1", type: "trojan", _subName: "BITZ", _subDisplayName: "Bitz" },
  { name: "香港 IPLC 01 GPT", type: "ss", subName: "TAG" },
  { name: "HK IPLC 02 Netflix", type: "ss", subName: "TAG" },
  { name: "日本 东京 2x", type: "trojan", provider: "Nexitally" },
  { name: "Singapore IPLC", type: "ss", subscription: { name: "FlowerCloud" } },
  { name: "Taiwan IEPL", type: "ss", _subName: "DlerCloud" },
  { name: "🇭🇰 香港实验性 IEPL 专线 1", type: "trojan", _subName: "huayun", _subDisplayName: "花云" },
  { name: "🇭🇰香港高速01|BGP|流媒体", type: "vless", _subName: "lx", _subDisplayName: "良心-共享" },
  { name: "United States Los Angeles 原生", type: "vmess" },
  { name: "官网 example.com", type: "ss", _subName: "huayun", _subDisplayName: "花云" },
];

const output = operator(input);
const names = output.map((proxy) => proxy.name);

assert(output.length === 11, "official notice node is filtered and traffic info is aggregated");
assert(names[0] === "花云 (137.51 GB/150 GB / 到期 2026-05-11)", "huayun traffic and expiry are aggregated");
assert(names[1] === "良心-共享 (剩余 4.13 TB / 到期 长期有效)", "lx traffic and expiry are aggregated");
assert(names.includes("Bitz 🇭🇰 香港 BGP"), "Bitz node prefers subscription display name");
assert(names.includes("TAG 🇭🇰 香港 IPLC GPT"), "Chinese Hong Kong node keeps provider, flag, IPLC, and GPT");
assert(names.includes("TAG 🇭🇰 香港 IPLC NF"), "English Hong Kong node keeps provider, flag, IPLC, and NF");
assert(names.includes("Nexitally 🇯🇵 日本 2x"), "Japan node uses its own subscription provider, flag, and rate");
assert(names.includes("FlowerCloud 🇸🇬 新加坡 IPLC"), "Singapore node uses nested subscription name");
assert(names.includes("DlerCloud 🇹🇼 台湾 IEPL"), "Taiwan node uses underscored subscription name");
assert(names.includes("花云 🇭🇰 香港 IEPL"), "huayun node prefers Chinese subscription display name");
assert(names.includes("良心-共享 🇭🇰 香港 BGP"), "lx node prefers Chinese subscription display name");
assert(names.includes("TAG 🇺🇸 美国 原生"), "United States node falls back to provider argument");
assert(output.every((proxy) => proxy["block-quic"] === "off"), "block-quic is set");
assert(names.indexOf("DlerCloud 🇹🇼 台湾 IEPL") < names.indexOf("Nexitally 🇯🇵 日本 2x"), "regular nodes are sorted by region after info nodes");

console.log("Sub-Store node rename tests passed.");
