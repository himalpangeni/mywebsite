const fs = require('fs');
const path = require('path');

const basePath = '/home/user/Documents/Web_Launch';

// 1. Fix index.html hrefs so local file loading works directly
const indexHtmlPath = path.join(basePath, 'index.html');
if (fs.existsSync(indexHtmlPath)) {
  let indexHtml = fs.readFileSync(indexHtmlPath, 'utf-8');
  indexHtml = indexHtml.replace(/href="(python|java|c|dotnet)\/([^"]+?)"/g, (match, folder, proj) => {
    if (proj.endsWith('.html')) return match;
    return `href="${folder}/${proj}/index.html"`;
  });
  fs.writeFileSync(indexHtmlPath, indexHtml);
  console.log('Fixed index.html links to point specifically to index.html.');
}

// 2. Re-generate Backend Architecture pages with corrected acronyms
const categories = ['python', 'java', 'c', 'dotnet'];
categories.forEach(category => {
  const catPath = path.join(basePath, category);
  if (!fs.existsSync(catPath)) return;

  const dirs = fs.readdirSync(catPath, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

  dirs.forEach(dirName => {
    const dirPath = path.join(catPath, dirName);
    
    // Correct casing for common technology acronyms
    let projectName = dirName.split('-').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
    projectName = projectName.replace(/\bAi\b/g, 'AI')
                             .replace(/\bApi\b/g, 'API')
                             .replace(/\bCli\b/g, 'CLI')
                             .replace(/\bUi\b/g, 'UI')
                             .replace(/\bOs\b/g, 'OS')
                             .replace(/\bHttp\b/g, 'HTTP')
                             .replace(/\bRest\b/g, 'REST');
                             
    const tag = category.toUpperCase() + ' Backend API';

    const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${projectName} - ${tag}</title>
  <style>
    body { margin: 0; padding: 0; height: 100vh; display: flex; align-items: center; justify-content: center; background: radial-gradient(circle at center, #1a1a2e, #16213e, #0f3460); font-family: sans-serif; color: white; }
    .card { background: rgba(255, 255, 255, 0.05); padding: 40px; border-radius: 16px; backdrop-filter: blur(15px); border: 1px solid rgba(255,255,255,0.1); max-width: 500px; text-align: center; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
    h1 { margin-top: 0; font-size: 2.2rem; background: linear-gradient(90deg, #00d2ff, #7000ff); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    p { color: #ccc; line-height: 1.6; font-size: 1.1rem; }
    .tag { display: inline-block; padding: 5px 12px; background: rgba(0, 210, 255, 0.2); border-radius: 20px; font-size: 0.8rem; font-weight: bold; margin-bottom: 20px; color: #00d2ff; }
    a.btn { display: inline-block; margin-top: 30px; padding: 12px 25px; background: #00d2ff; color: #000; text-decoration: none; border-radius: 8px; font-weight: bold; transition: 0.3s; }
    a.btn:hover { background: #7000ff; color: #fff; transform: translateY(-2px); }
  </style>
</head>
<body>
  <div class="card">
    <div class="tag">${tag}</div>
    <h1>${projectName}</h1>
    <p>This is a dedicated backend architecture stub for <strong>${projectName}</strong> seamlessly separated for proper modular routing.</p>
    <a href="../../index.html" class="btn">Return to Project Hub</a>
  </div>
</body>
</html>`;

    fs.writeFileSync(path.join(dirPath, 'index.html'), htmlContent);
    console.log(`Corrected: ${category}/${dirName}/index.html`);
  });
});
