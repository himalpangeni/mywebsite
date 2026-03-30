const fs = require('fs');
const path = require('path');

const basePath = '/home/user/Documents/Web_Launch';
const indexHtmlPath = path.join(basePath, 'index.html');
const indexHtml = fs.readFileSync(indexHtmlPath, 'utf8');

const regex = /href=(["'])(.*?)\1/g;
let match;
let missing = [];
let total = 0;

while ((match = regex.exec(indexHtml)) !== null) {
  let link = match[2];
  if (link.startsWith('http') || link.startsWith('#') || link.startsWith('mailto:')) continue;
  
  let fullPath = path.join(basePath, link);
  total++;
  // Remove URL query params if any
  fullPath = fullPath.split('?')[0];

  if (!fs.existsSync(fullPath)) {
    missing.push(link);
  }
}

console.log('Total Links Checked:', total);
if (missing.length > 0) {
  console.log('Missing files:\\n' + missing.join('\\n'));
} else {
  console.log('All linked files exist and are correctly pathed.');
}
