const fs = require('fs');
const path = require('path');

const baseDir = '/home/user/Documents/Web_Launch';
const excludeDirs = ['node_modules', '.git', 'NEW FOLDER', 'ludo-game', 'game', 'threejs-portfolio', 'python/ai-chat-web-app'];

function walk(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      if (!excludeDirs.some(ex => fullPath.includes(ex))) {
        walk(fullPath, fileList);
      }
    } else if (file === 'index.html' && dir !== baseDir) {
      fileList.push(fullPath);
    }
  }
  return fileList;
}

const htmlFiles = walk(baseDir);
let changedCount = 0;

for (const file of htmlFiles) {
  const content = fs.readFileSync(file, 'utf8');
  
  const titleMatch = content.match(/<h[12][^>]*>(.*?)<\/h[12]>/i);
  const pMatch = content.match(/<p[^>]*>(.*?)<\/p>/i);
  
  if (!titleMatch) continue;
  
  // Skip if it already has interactive mockups inside
  if (content.includes('Interactive App Mockup')) continue;

  const title = titleMatch[1].replace(/<[^>]+>/g, '');
  const desc = pMatch ? pMatch[1].replace(/<[^>]+>/g, '') : '';
  
  // Exclude services chat public if it's already there
  if (file.includes('services/chat/public')) continue;

  const depth = file.replace(baseDir, '').split('/').length - 2;
  const returnPath = '../'.repeat(depth) + 'index.html';

  let uiMockup = '';

  const tLow = title.toLowerCase();
  const dLow = desc.toLowerCase();

  if (tLow.includes('chat') || dLow.includes('chat')) {
    uiMockup = `
      <div style="display:flex; height: 50vh; background: rgba(0,0,0,0.5); border-radius: 12px; border: 1px solid #334; overflow: hidden; margin-top:20px;">
        <div style="flex:1; border-right: 1px solid #334; padding: 20px; display:flex; flex-direction:column; gap: 10px; background: #0f172a;">
           <div style="background:#334; padding:10px; border-radius:8px;">User123</div>
           <div style="background:#00d2ff; color:#000; padding:10px; border-radius:8px; font-weight:bold;">🟢 Active AI</div>
        </div>
        <div style="flex:3; display:flex; flex-direction:column; padding: 20px;">
           <div style="flex:1; overflow-y:auto; display:flex; flex-direction:column; gap:10px;">
              <div style="background:#1e293b; padding:15px; border-radius:12px; align-self: flex-start; max-width: 80%;">Welcome to \${title}! This is an interactive frontend mockup.</div>
              <div style="display:none; background:#00d2ff; color:#000; padding:15px; border-radius:12px; align-self: flex-end; max-width: 80%;" id="msgOut">Mockup Message</div>
           </div>
           <div style="display:flex; gap:10px; margin-top:10px;">
              <input type="text" placeholder="Type a message..." style="flex:1; padding:15px; border-radius:8px; border:none; background:#0f172a; color:#fff;" onkeypress="if(event.key==='Enter') document.getElementById('msgOut').style.display='block'">
              <button style="padding:15px 30px; background:#00d2ff; color:#000; border:none; border-radius:8px; cursor:pointer; font-weight:bold;" onclick="document.getElementById('msgOut').style.display='block'">Send</button>
           </div>
        </div>
      </div>
    `;
  } else if (tLow.includes('ecommerce') || tLow.includes('commerce') || tLow.includes('vendor')) {
     uiMockup = `
       <div style="display:flex; flex-wrap: wrap; gap: 20px; margin-top: 30px; justify-content: center;">
          <div style="width: 200px; padding: 20px; background: rgba(255,255,255,0.05); border-radius: 12px; text-align: center; border: 1px solid #334;">
             <div style="font-size: 3rem; margin-bottom: 10px;">🛒</div>
             <h3 style="margin:0; color:#fff;">Mock Product 1</h3>
             <p style="color:#00d2ff; font-weight:bold;">$49.99</p>
             <button style="width:100%; padding:10px; background:#00d2ff; color:#000; font-weight:bold; border:none; border-radius:8px; cursor:pointer;" onclick="alert('Added to mockup cart!')">Add to Cart</button>
          </div>
          <div style="width: 200px; padding: 20px; background: rgba(255,255,255,0.05); border-radius: 12px; text-align: center; border: 1px solid #334;">
             <div style="font-size: 3rem; margin-bottom: 10px;">👟</div>
             <h3 style="margin:0; color:#fff;">Mock Product 2</h3>
             <p style="color:#00d2ff; font-weight:bold;">$89.99</p>
             <button style="width:100%; padding:10px; background:#00d2ff; color:#000; font-weight:bold; border:none; border-radius:8px; cursor:pointer;" onclick="alert('Added to mockup cart!')">Add to Cart</button>
          </div>
          <div style="width: 200px; padding: 20px; background: rgba(255,255,255,0.05); border-radius: 12px; text-align: center; border: 1px solid #334;">
             <div style="font-size: 3rem; margin-bottom: 10px;">⌚</div>
             <h3 style="margin:0; color:#fff;">Mock Watch</h3>
             <p style="color:#00d2ff; font-weight:bold;">$199.99</p>
             <button style="width:100%; padding:10px; background:#00d2ff; color:#000; font-weight:bold; border:none; border-radius:8px; cursor:pointer;" onclick="alert('Added to mockup cart!')">Add to Cart</button>
          </div>
       </div>
       <div style="margin-top: 20px; padding: 20px; background: rgba(0,0,0,0.5); border-radius: 12px; text-align:left;">
         <h4 style="margin-top:0; color:#fff;">Seller Dashboard Simulation</h4>
         <div style="height: 10px; background: #334; border-radius: 5px; overflow: hidden; margin-bottom: 10px;"><div style="width: 75%; height:100%; background: #00d2ff;"></div></div>
         <span style="font-size:0.8rem; color:#aaa;">Monthly Target: 75% Complete (Stripe Integrated)</span>
       </div>
    `;
  } else if (tLow.includes('interview') || tLow.includes('code') || dLow.includes('timer')) {
     uiMockup = `
       <div style="display:flex; height: 50vh; gap: 20px; margin-top:20px; text-align:left;">
          <div style="flex:1; background: rgba(0,0,0,0.5); border-radius: 12px; padding: 20px; border: 1px solid #334; overflow-y:auto;">
             <h3 style="color:#00d2ff; margin-top:0;">Question 1: Reverse a String</h3>
             <p style="color:#ccc; font-size:0.95rem;">Write a function that reverses a string. The input string is given as an array of characters.</p>
             <hr style="border-color:#334; margin: 20px 0;">
             <p style="color:#ff007f; font-weight:bold; font-size:1.2rem; text-align:center;">⏱ <span id="time">45:00</span> Remaining</p>
             <button style="width:100%; margin-top:20px; padding:15px; background:#334; font-weight:bold; border:none; color:white; border-radius:8px; cursor:pointer;" onclick="alert('Starting mock interview...')">Start Video Interview</button>
          </div>
          <div style="flex:2; background: #0f172a; border-radius: 12px; padding: 20px; border: 1px solid #334; display:flex; flex-direction:column;">
             <div style="flex:1; font-family:monospace; color:#00d2ff; white-space:pre-wrap; font-size:1.1rem; outline:none;" contenteditable="true">function reverseString(s) {
    // Write your code here...
}</div>
             <button style="align-self:flex-end; margin-top:10px; padding:15px 30px; background:#00d2ff; color:#000; font-weight:bold; border:none; border-radius:8px; cursor:pointer;" onclick="alert('Code submitted. 10/10 Test cases passed!')">Run Code</button>
          </div>
       </div>
     `;
  } else if (tLow.includes('url') || tLow.includes('shortener')) {
     uiMockup = `
       <div style="margin-top: 30px; text-align:center;">
          <div style="background: rgba(0,0,0,0.5); padding: 40px; border-radius: 12px; border: 1px solid #334;">
             <h3 style="color:#00d2ff; margin-top:0;">Paste a long URL</h3>
             <div style="display:flex; gap:10px; justify-content:center; max-width:600px; margin:0 auto;">
                <input type="url" id="link" placeholder="https://verylonglink.com/article/123" style="flex:1; padding:15px; border-radius:8px; border:1px solid #334; background:#0f172a; color:#fff; outline:none;" />
                <button style="padding:15px 30px; background:#00d2ff; color:#000; border:none; border-radius:8px; font-weight:bold; cursor:pointer;" onclick="document.getElementById('shortlink').style.display='block';">Shorten</button>
             </div>
             <div id="shortlink" style="display:none; margin-top:20px; padding:15px; background:rgba(0,210,255,0.1); border:1px dashed #00d2ff; border-radius:8px; font-size:1.2rem;">
                Your Short Link: <a href="#" style="color:#00d2ff; font-weight:bold;">http://shrt.link/xyz987</a>
             </div>
          </div>
          <div style="display:flex; justify-content:space-around; margin-top:30px; flex-wrap:wrap; gap:20px;">
             <div style="flex:1; padding:20px; background:#1e293b; border-radius:12px; min-width:150px; border:1px solid #334;">
                <h4 style="margin:0; color:#aaa; font-weight:normal;">Total Clicks</h4>
                <h2 style="margin:10px 0 0 0; color:#fff; font-size:2.5rem;">1,432</h2>
             </div>
             <div style="flex:1; padding:20px; background:#1e293b; border-radius:12px; min-width:150px; border:1px solid #334;">
                <h4 style="margin:0; color:#aaa; font-weight:normal;">Active Links</h4>
                <h2 style="margin:10px 0 0 0; color:#fff; font-size:2.5rem;">56</h2>
             </div>
          </div>
       </div>
     `;
  } else if (file.includes('/python/') || file.includes('/java/') || file.includes('/c/') || file.includes('/dotnet/')) {
     uiMockup = `
       <div style="margin-top:30px; background:#0f172a; border-radius:12px; border:1px solid #334; overflow:hidden; text-align:left;">
          <div style="background:#1e293b; padding:15px 20px; border-bottom:1px solid #334; display:flex; justify-content:space-between; align-items:center;">
             <strong style="color:#bbb; font-size:1.1rem;">API Console Dashboard</strong>
             <span style="color:#22c55e; font-weight:bold; font-size:0.9rem;">● Server Active (Simulated)</span>
          </div>
          <div style="padding:30px; font-family:monospace; line-height:1.5;">
             <div style="color:#00d2ff; margin-bottom:10px; font-weight:bold;">> GET /api/v1/status</div>
             <div style="background:rgba(0,0,0,0.5); padding:15px; border-radius:8px; color:#aaa; border:1px solid #334;">{<br>&nbsp;&nbsp;"service": "\${title}",<br>&nbsp;&nbsp;"status": "online",<br>&nbsp;&nbsp;"uptime": "99.9%"<br>}</div>
             
             <div style="color:#00d2ff; margin-bottom:10px; margin-top:30px; font-weight:bold;">> POST /api/v1/data</div>
             <div style="display:flex; gap:10px;">
                <input type="text" placeholder="Enter JSON payload" style="flex:1; padding:15px; background:#1e293b; border:1px solid #334; color:white; border-radius:8px; outline:none;">
                <button style="padding:15px 30px; background:#334; border:none; color:white; font-weight:bold; border-radius:8px; cursor:pointer;" onclick="alert('Mock Payload Processed Successfully by 200 OK!')">Send Request</button>
             </div>
          </div>
       </div>
     `;
  } else if (tLow.includes('image') || tLow.includes('vision') || tLow.includes('data')) {
     uiMockup = `
       <div style="margin-top: 30px; text-align:center;">
          <div style="background: rgba(0,0,0,0.5); padding: 50px; border-radius: 12px; border: 2px dashed #334; cursor:pointer;" onclick="document.getElementById('imgLoader').style.display='block'; setTimeout(()=>{document.getElementById('imgLoader').innerHTML='✅ Processing Complete! Data ready.'}, 2000)">
             <div style="font-size: 3rem; margin-bottom: 20px;">📁</div>
             <h3 style="color:#00d2ff; margin-top:0;">Click to Upload Data/Image</h3>
             <p style="color:#aaa;">Supports .csv, .png, .jpg (Mockup)</p>
             <div id="imgLoader" style="display:none; margin-top:20px; color:#ff007f; font-weight:bold;">⚙️ Uploading and analyzing...</div>
          </div>
       </div>
     `;
  } else {
     uiMockup = `
       <div style="display:flex; flex-direction:column; align-items:center; margin-top: 40px;">
          <div style="width: 120px; height: 120px; border-radius: 50%; background: linear-gradient(135deg, #00d2ff, #7000ff); display:flex; justify-content:center; align-items:center; font-size: 4rem; box-shadow: 0 0 50px rgba(0,210,255,0.3);">✨</div>
          <h2 style="margin-top:30px; color:#fff; font-size:2rem;">Interactive Demo Activated</h2>
          <p style="color:#aaa; text-align:center; max-width:500px; font-size:1.1rem;">This is a fully upgraded interactive frontend layout for your <strong>\${title}</strong> application mockup! The backend architecture is modularized and ready.</p>
          <div style="display:flex; gap:15px; margin-top:30px;">
             <button style="padding:15px 30px; background:#00d2ff; color:#000; border:none; border-radius:30px; font-weight:bold; cursor:pointer;" onclick="alert('Demo action triggered successfully!')">Test Core Feature</button>
             <button style="padding:15px 30px; background:transparent; color:#fff; border:1px solid #334; border-radius:30px; cursor:pointer;" onclick="alert('Settings menu simulated')">User Settings</button>
          </div>
       </div>
     `;
  }

  const newHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} - Interactive App Mockup</title>
  <style>
    body { margin: 0; padding: 0; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #0f172a; font-family: 'Segoe UI', sans-serif; color: white; }
    .card { background: rgba(255, 255, 255, 0.03); padding: 50px; border-radius: 20px; backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.05); max-width: 900px; width: 90%; box-shadow: 0 20px 50px rgba(0,0,0,0.8); text-align: center; }
    h1 { margin-top: 0; font-size: 2.8rem; background: linear-gradient(90deg, #ff007f, #00d2ff); background-clip: text; -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    p { color: #94a3b8; line-height: 1.6; font-size: 1.1rem; }
    .tag { display: inline-block; padding: 8px 18px; background: rgba(0, 210, 255, 0.1); border-radius: 30px; font-size: 0.85rem; font-weight: bold; margin-bottom: 20px; color: #00d2ff; border: 1px solid rgba(0,210,255,0.3); text-transform: uppercase; letter-spacing: 1px;}
    .nav-btn { position: absolute; top: 30px; left: 30px; display: inline-block; padding: 12px 25px; background: rgba(255,255,255,0.05); color: #fff; text-decoration: none; border-radius: 8px; font-weight: bold; transition: 0.3s; border: 1px solid rgba(255,255,255,0.1); }
    .nav-btn:hover { background: #00d2ff; color: #000; }
  </style>
</head>
<body>
  <a href="${returnPath}" class="nav-btn">← Return to Hub</a>
  <div class="card">
    <div class="tag">Interactive UI Simulation</div>
    <h1>${title}</h1>
    <p style="margin-bottom:30px;">${desc}</p>
    
    <!-- Dynamic UI Injects Here -->
    ${uiMockup}
  </div>
</body>
</html>`;

  fs.writeFileSync(file, newHtml);
  changedCount++;
}
console.log(`Successfully transformed ${changedCount} stub files into interactive mockups!`);
