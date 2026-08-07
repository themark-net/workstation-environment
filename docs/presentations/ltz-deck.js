const fs = require("fs");
const zlib = require("zlib");
const path = require("path");
const a = fs.readFileSync(path.join(__dirname, "ltz-deck.b64a"), "utf8").trim();
const b = fs.readFileSync(path.join(__dirname, "ltz-deck.b64b"), "utf8").trim();
const js = zlib.gunzipSync(Buffer.from(a + b, "base64")).toString("utf8");
const target = path.join(__dirname, "ltz-deck.expanded.js");
fs.writeFileSync(target, js);
require("child_process").spawnSync(process.execPath, [target], { stdio: "inherit", env: process.env });
