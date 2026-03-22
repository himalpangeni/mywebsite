const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const basePath = '/home/user/Documents/Web_Launch';

const servers = [
  { file: 'strangify/server.js', port: 3005 },
  { file: 'services/chat/server.js', port: 3001 },
  { file: 'services/ludo/server.js', port: 3003 },
  { file: 'services/snake/server.js', port: 3004 },
  { file: 'services/resume/server.js', port: 3002 }
];

console.log('--- Starting Web_Launch Daemon Services ---');

servers.forEach(srv => {
  const fullPath = path.join(basePath, srv.file);
  
  if (fs.existsSync(fullPath)) {
    console.log(`[BOOT] Attempting to start Node on Port ${srv.port} -> ${srv.file}`);
    
    // Spawn the node process
    const child = spawn('node', [fullPath], {
      cwd: path.dirname(fullPath),
      detached: true,
      stdio: 'ignore'
    });
    
    // Unref so the daemon script itself doesn't hang in the foreground
    child.unref();

    console.log(`[SUCCESS] Detached process started for ${srv.file}`);
  } else {
    console.log(`[ERROR] Missing expected server file: ${srv.file}`);
  }
});

console.log('--- All daemon services have been fired in the background. ---');
