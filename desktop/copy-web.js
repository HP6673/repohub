// Copies the website into the app bundle so the desktop app ships the same page.
const fs = require("fs");
const path = require("path");

const dest = path.join(__dirname, "web");
fs.mkdirSync(dest, { recursive: true });
fs.copyFileSync(path.join(__dirname, "..", "index.html"), path.join(dest, "index.html"));
