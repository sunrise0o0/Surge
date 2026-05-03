/**
 * Rabbit-Spec Sub-Store node rename script.
 *
 * Usage:
 *   Add this file as a Sub-Store script operation.
 *
 * Recommended:
 *   Node-Rename.js#provider=TAG&flag&one&keep=gpt+nf+iplc&blockquic=off
 *
 * Arguments:
 *   provider/name  Fallback provider prefix when a node has no subscription name.
 *   out            cn/zh, en, flag, quan. Default: cn.
 *   flag           Prefix country flag before country name.
 *   one            Remove sequence number when a region has only one node.
 *   keep           Extra case-insensitive keywords to preserve, separated by +.
 *   clear          Drop traffic, expire, official-site, support, and notice nodes.
 *   sep            Separator between name parts. Default: space.
 *   sn             Separator before sequence number. Default: space.
 *   blockquic      on/off. Set or remove block-quic.
 */

const ARG = typeof $arguments !== "undefined" && $arguments ? $arguments : {};

const COUNTRIES = [
  {
    code: "HK",
    cn: "香港",
    quan: "Hong Kong",
    flag: "🇭🇰",
    patterns: [/香港|港(?!口)|Hong\s?Kong|Hongkong|\bHK\b|🇭🇰/i],
  },
  {
    code: "MO",
    cn: "澳门",
    quan: "Macao",
    flag: "🇲🇴",
    patterns: [/澳门|澳門|Macao|Macau|\bMO\b|🇲🇴/i],
  },
  {
    code: "TW",
    cn: "台湾",
    quan: "Taiwan",
    flag: "🇹🇼",
    patterns: [/台湾|台灣|台北|新北|Taiwan|Taipei|\bTW\b|🇹🇼/i],
  },
  {
    code: "JP",
    cn: "日本",
    quan: "Japan",
    flag: "🇯🇵",
    patterns: [/日本|东京|東京|大阪|Japan|Tokyo|Osaka|\bJP\b|🇯🇵/i],
  },
  {
    code: "KR",
    cn: "韩国",
    quan: "Korea",
    flag: "🇰🇷",
    patterns: [/韩国|韓国|韓國|首尔|首爾|春川|Korea|Seoul|\bKR\b|🇰🇷/i],
  },
  {
    code: "SG",
    cn: "新加坡",
    quan: "Singapore",
    flag: "🇸🇬",
    patterns: [/新加坡|狮城|獅城|Singapore|\bSG\b|🇸🇬/i],
  },
  {
    code: "US",
    cn: "美国",
    quan: "United States",
    flag: "🇺🇸",
    patterns: [/美国|美國|洛杉矶|洛杉磯|圣何塞|聖何塞|西雅图|西雅圖|纽约|紐約|United\s?States|USA|America|Los\s?Angeles|San\s?Jose|Seattle|New\s?York|\bUS\b|🇺🇸/i],
  },
  {
    code: "GB",
    cn: "英国",
    quan: "United Kingdom",
    flag: "🇬🇧",
    patterns: [/英国|英國|伦敦|倫敦|United\s?Kingdom|Great\s?Britain|London|\bUK\b|\bGB\b|🇬🇧/i],
  },
  {
    code: "CA",
    cn: "加拿大",
    quan: "Canada",
    flag: "🇨🇦",
    patterns: [/加拿大|多伦多|多倫多|温哥华|溫哥華|Canada|Toronto|Vancouver|\bCA\b|🇨🇦/i],
  },
  {
    code: "AU",
    cn: "澳大利亚",
    quan: "Australia",
    flag: "🇦🇺",
    patterns: [/澳大利亚|澳大利亞|澳洲|悉尼|墨尔本|墨爾本|Australia|Sydney|Melbourne|\bAU\b|🇦🇺/i],
  },
  {
    code: "DE",
    cn: "德国",
    quan: "Germany",
    flag: "🇩🇪",
    patterns: [/德国|德國|法兰克福|法蘭克福|Germany|Frankfurt|\bDE\b|🇩🇪/i],
  },
  {
    code: "FR",
    cn: "法国",
    quan: "France",
    flag: "🇫🇷",
    patterns: [/法国|法國|巴黎|France|Paris|\bFR\b|🇫🇷/i],
  },
  {
    code: "NL",
    cn: "荷兰",
    quan: "Netherlands",
    flag: "🇳🇱",
    patterns: [/荷兰|荷蘭|阿姆斯特丹|Netherlands|Amsterdam|\bNL\b|🇳🇱/i],
  },
  {
    code: "TR",
    cn: "土耳其",
    quan: "Turkey",
    flag: "🇹🇷",
    patterns: [/土耳其|伊斯坦布尔|伊斯坦堡|Turkey|Istanbul|\bTR\b|🇹🇷/i],
  },
  {
    code: "IN",
    cn: "印度",
    quan: "India",
    flag: "🇮🇳",
    patterns: [/印度|孟买|孟買|India|Mumbai|\bIN\b|🇮🇳/i],
  },
  {
    code: "TH",
    cn: "泰国",
    quan: "Thailand",
    flag: "🇹🇭",
    patterns: [/泰国|泰國|曼谷|Thailand|Bangkok|\bTH\b|🇹🇭/i],
  },
  {
    code: "VN",
    cn: "越南",
    quan: "Vietnam",
    flag: "🇻🇳",
    patterns: [/越南|Vietnam|\bVN\b|🇻🇳/i],
  },
  {
    code: "PH",
    cn: "菲律宾",
    quan: "Philippines",
    flag: "🇵🇭",
    patterns: [/菲律宾|菲律賓|Philippines|\bPH\b|🇵🇭/i],
  },
  {
    code: "ID",
    cn: "印尼",
    quan: "Indonesia",
    flag: "🇮🇩",
    patterns: [/印尼|印度尼西亚|印度尼西亞|雅加达|雅加達|Indonesia|Jakarta|\bID\b|🇮🇩/i],
  },
  {
    code: "MY",
    cn: "马来西亚",
    quan: "Malaysia",
    flag: "🇲🇾",
    patterns: [/马来|馬來|Malaysia|\bMY\b|🇲🇾/i],
  },
  {
    code: "RU",
    cn: "俄罗斯",
    quan: "Russia",
    flag: "🇷🇺",
    patterns: [/俄罗斯|俄羅斯|莫斯科|Russia|Moscow|\bRU\b|🇷🇺/i],
  },
];

const DEFAULT_KEEP = [
  [/IPLC/i, "IPLC"],
  [/IEPL/i, "IEPL"],
  [/\bBGP\b/i, "BGP"],
  [/\bCN2\b/i, "CN2"],
  [/家宽|家寬|住宅|原生|Native/i, "原生"],
  [/商宽|商寬/i, "商宽"],
  [/游戏|遊戲|\bGame\b/i, "Game"],
  [/\bGPT\b|OpenAI|ChatGPT/i, "GPT"],
  [/\bNF\b|Netflix/i, "NF"],
  [/Disney|\bD\+/i, "Disney"],
  [/\bTikTok\b/i, "TikTok"],
  [/\bUDP\b/i, "UDP"],
  [/倍率\s*[:：]?\s*(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(?:x|X|×|倍)/i, null],
];

const INFO_RE = /(套餐|到期|有效|剩余|剩餘|流量|Traffic|Expire|Expired|Remain|Remaining|Used|Total)/i;
const DROP_RE = /(官网|官網|网址|網址|客服|工单|工單|邮箱|郵箱|订阅|訂閱|公告|通知|Official|Website|Support|Email|Notice)/i;

function getArg(name, fallback) {
  return ARG[name] === undefined || ARG[name] === "" ? fallback : decodeValue(ARG[name]);
}

function hasArg(name) {
  return Boolean(ARG[name]);
}

function decodeValue(value) {
  try {
    return decodeURIComponent(String(value));
  } catch (_) {
    return String(value);
  }
}

function normalizeOutputMode(value) {
  const mode = String(value || "cn").toLowerCase();
  if (mode === "zh") return "cn";
  if (mode === "us") return "en";
  if (mode === "gq") return "flag";
  return ["cn", "en", "flag", "quan"].indexOf(mode) >= 0 ? mode : "cn";
}

function normalizeText(value) {
  return String(value || "")
    .replace(/[|｜·・_/\\[\](){}【】「」『』"'`~!@#$%^&*=+<>?，。；：:、]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

const PROVIDER_KEYS = [
  "_subDisplayName",
  "subDisplayName",
  "_subscriptionDisplayName",
  "subscriptionDisplayName",
  "_collectionDisplayName",
  "collectionDisplayName",
  "_sourceDisplayName",
  "sourceDisplayName",
  "_originDisplayName",
  "originDisplayName",
  "providerDisplayName",
  "provider",
  "providerName",
  "subName",
  "_subName",
  "subscription",
  "subscriptionName",
  "_subscription",
  "_subscriptionName",
  "collectionName",
  "_collectionName",
  "source",
  "sourceName",
  "_source",
  "_sourceName",
  "origin",
  "originName",
  "_origin",
  "_originName",
];

const PROVIDER_OBJECT_KEYS = ["name", "displayName", "label", "title", "remark", "remarks"];

function pickString(value) {
  if (typeof value === "string" && value.trim()) return value.trim();
  if (typeof value === "number" && Number.isFinite(value)) return String(value);
  return "";
}

function pickProviderFromObject(object) {
  if (!object || typeof object !== "object") return "";

  for (let i = 0; i < PROVIDER_KEYS.length; i++) {
    const value = object[PROVIDER_KEYS[i]];
    const direct = pickString(value);
    if (direct) return direct;

    if (value && typeof value === "object") {
      for (let j = 0; j < PROVIDER_OBJECT_KEYS.length; j++) {
        const nested = pickString(value[PROVIDER_OBJECT_KEYS[j]]);
        if (nested) return nested;
      }
    }
  }

  return "";
}

function getProvider(proxy, runtimeContext) {
  const fromProxy = pickProviderFromObject(proxy);

  if (fromProxy) return String(fromProxy);

  const fromContext = pickProviderFromObject(runtimeContext);
  if (fromContext) return String(fromContext);

  return getArg("provider", "") || getArg("name", "");
}

function detectCountry(name) {
  for (let i = 0; i < COUNTRIES.length; i++) {
    const country = COUNTRIES[i];
    for (let j = 0; j < country.patterns.length; j++) {
      if (country.patterns[j].test(name)) {
        return country;
      }
    }
  }
  return null;
}

function formatCountry(country, mode, withFlag) {
  if (!country) return "";
  const value = mode === "en" ? country.code : mode === "flag" ? country.flag : mode === "quan" ? country.quan : country.cn;
  if (withFlag && mode !== "flag") return country.flag + " " + value;
  return value;
}

function uniquePush(list, value) {
  if (value && list.indexOf(value) < 0) list.push(value);
}

function collectTags(name) {
  const tags = [];

  DEFAULT_KEEP.forEach((entry) => {
    const regex = entry[0];
    const label = entry[1];
    const match = name.match(regex);
    if (!match) return;

    if (label) {
      uniquePush(tags, label);
      return;
    }

    const rate = match[1] || match[2];
    if (rate && rate !== "1") uniquePush(tags, rate + "x");
  });

  const extra = getArg("keep", "") || getArg("blkey", "");
  if (extra) {
    extra.split("+").forEach((item) => {
      const pair = item.split(">");
      const key = pair[0];
      const label = pair[1] || pair[0];
      if (key && name.toLowerCase().indexOf(key.toLowerCase()) >= 0) {
        uniquePush(tags, label);
      }
    });
  }

  return tags;
}

function setBlockQuic(proxy) {
  const value = getArg("blockquic", "");
  if (value === "on") {
    proxy["block-quic"] = "on";
  } else if (value === "off") {
    proxy["block-quic"] = "off";
  }
}

function buildBaseName(proxy, country, tags, runtimeContext) {
  const provider = getProvider(proxy, runtimeContext);
  const mode = normalizeOutputMode(getArg("out", "cn"));
  const withFlag = hasArg("flag");
  const sep = getArg("sep", " ");
  const countryName = formatCountry(country, mode, withFlag);
  const parts = [];

  uniquePush(parts, provider);
  uniquePush(parts, countryName);
  tags.forEach((tag) => uniquePush(parts, tag));

  return parts.join(sep);
}

function buildInfoName(proxy, cleanName, runtimeContext) {
  const provider = getProvider(proxy, runtimeContext);
  const sep = getArg("sep", " ");
  return [provider, cleanName].filter(Boolean).join(sep);
}

function parseInfo(cleanName) {
  const info = {};
  const traffic = cleanName.match(/(?:Traffic|流量|剩余流量)\s*([0-9.]+)\s*([KMGT]B)?(?:\s+|\s*\/\s*|\s*\|\s*)([0-9.]+)?\s*([KMGT]B)?/i);
  const expire = cleanName.match(/(?:Expire|Expired|到期|套餐到期)\s*([0-9]{4}[-/.][0-9]{1,2}[-/.][0-9]{1,2}|长期有效|永久|無限期|无限期|Unlimited)/i);

  if (traffic) {
    const first = traffic[1] ? traffic[1] + " " + (traffic[2] || traffic[4] || "").trim() : "";
    const second = traffic[3] ? traffic[3] + " " + (traffic[4] || traffic[2] || "").trim() : "";

    if (/剩余|剩餘|Remain|Remaining/i.test(cleanName)) {
      info.remaining = first.trim();
      if (second) info.total = second.trim();
    } else {
      info.used = first.trim();
      if (second) info.total = second.trim();
    }
  }

  if (expire) {
    info.expire = expire[1].replace(/[/.]/g, "-");
  }

  return info;
}

function mergeInfo(target, source) {
  if (!target.used && source.used) target.used = source.used;
  if (!target.remaining && source.remaining) target.remaining = source.remaining;
  if (!target.total && source.total) target.total = source.total;
  if (!target.expire && source.expire) target.expire = source.expire;
}

function formatInfoName(provider, info) {
  const parts = [];

  if (info.used && info.total) {
    parts.push(info.used + "/" + info.total);
  } else if (info.remaining && info.total) {
    parts.push("剩余 " + info.remaining + "/" + info.total);
  } else if (info.used) {
    parts.push("已用 " + info.used);
  } else if (info.remaining) {
    parts.push("剩余 " + info.remaining);
  } else if (info.total) {
    parts.push("总量 " + info.total);
  }

  if (info.expire) {
    parts.push("到期 " + info.expire);
  }

  if (parts.length === 0) {
    return provider;
  }

  return provider + " (" + parts.join(" / ") + ")";
}

function removeSingleSequence(proxies, separator) {
  const counts = {};
  proxies.forEach((proxy) => {
    const base = proxy.name.replace(new RegExp(separator.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\d{2}$"), "");
    counts[base] = (counts[base] || 0) + 1;
  });

  proxies.forEach((proxy) => {
    const base = proxy.name.replace(new RegExp(separator.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\d{2}$"), "");
    if (counts[base] === 1) proxy.name = base;
  });
}

function operator(proxies, targetPlatform, runtimeContext) {
  const separator = getArg("sn", " ");
  const keepUnknown = hasArg("keepUnknown") || hasArg("nm");
  const shouldClear = hasArg("clear");
  const shouldSort = !hasArg("noSort");
  const counters = {};
  const output = [];
  const infoByProvider = {};
  const infoOrder = [];

  proxies.forEach((proxy, index) => {
    const originalName = String(proxy.name || "");
    const cleanName = normalizeText(originalName);
    const provider = getProvider(proxy, runtimeContext);

    if (shouldClear && DROP_RE.test(cleanName)) return;

    if (INFO_RE.test(cleanName)) {
      const info = parseInfo(cleanName);
      if (!infoByProvider[provider]) {
        infoByProvider[provider] = {
          proxy: proxy,
          info: {},
          index: index,
        };
        infoOrder.push(provider);
      }
      mergeInfo(infoByProvider[provider].info, info);
      return;
    }

    const country = detectCountry(cleanName);
    if (!country && !keepUnknown) return;

    const tags = collectTags(cleanName);
    const baseName = country ? buildBaseName(proxy, country, tags, runtimeContext) : [getProvider(proxy, runtimeContext), cleanName].filter(Boolean).join(getArg("sep", " "));
    counters[baseName] = (counters[baseName] || 0) + 1;

    proxy.name = baseName + separator + String(counters[baseName]).padStart(2, "0");
    proxy._rsSort = {
      type: 1,
      provider: provider,
      country: country ? COUNTRIES.indexOf(country) : 999,
      base: baseName,
      index: index,
    };
    setBlockQuic(proxy);
    output.push(proxy);
  });

  if (hasArg("one")) {
    removeSingleSequence(output, separator);
  }

  infoOrder.forEach((provider) => {
    const entry = infoByProvider[provider];
    entry.proxy.name = formatInfoName(provider, entry.info);
    entry.proxy._rsSort = {
      type: 0,
      provider: provider,
      country: -1,
      base: entry.proxy.name,
      index: entry.index,
    };
    setBlockQuic(entry.proxy);
    output.push(entry.proxy);
  });

  if (shouldSort) {
    output.sort((a, b) => {
      if (a._rsSort.type !== b._rsSort.type) return a._rsSort.type - b._rsSort.type;
      if (a._rsSort.provider !== b._rsSort.provider) return a._rsSort.provider.localeCompare(b._rsSort.provider);
      if (a._rsSort.country !== b._rsSort.country) return a._rsSort.country - b._rsSort.country;
      if (a._rsSort.base !== b._rsSort.base) return a._rsSort.base.localeCompare(b._rsSort.base);
      return a._rsSort.index - b._rsSort.index;
    });
  }

  output.forEach((proxy) => {
    delete proxy._rsSort;
  });

  return output;
}

if (typeof module !== "undefined") {
  module.exports = { operator };
}
