// Simple Resume Analyzer server (stub)
// Run locally:
// cd services/resume
// npm init -y
// npm install express cors body-parser
// node server.js

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(bodyParser.json({ limit: '2mb' }));
app.use(express.static(path.join(__dirname, 'public')));

const KEY_SKILLS = ['javascript','java','python','react','node','express','html','css','sql','mongodb','docker','aws','git','typescript'];

function analyzeText(text){
  const lower = (text||'').toLowerCase();
  const words = lower.split(/\W+/).filter(Boolean);
  const wordCount = words.length;
  // basic sections detection
  const hasContact = /contact|email|phone|mobile/.test(lower);
  const hasEducation = /education|degree|bachelor|master|university|college/.test(lower);
  const hasExperience = /experience|worked|\bproject\b|internship|developer/.test(lower);
  const hasSkills = /skills|technologies|tech stack|proficiencies/.test(lower);

  const skillsFound = [];
  KEY_SKILLS.forEach(k=>{ if(lower.includes(k)) skillsFound.push(k); });

  // score out of 100 (naive)
  let score = 40;
  if(hasContact) score += 15;
  if(hasEducation) score += 10;
  if(hasExperience) score += 15;
  if(hasSkills) score += 10;
  score += Math.min(20, Math.floor(skillsFound.length * 3));
  if(wordCount > 1000) score = Math.max(0, score - 5);

  const suggestions = [];
  if(!hasContact) suggestions.push('Add a clear contact section (email and phone).');
  if(!hasExperience) suggestions.push('Add concrete experience or project descriptions with outcomes and technologies used.');
  if(skillsFound.length < 3) suggestions.push('List more technical skills and tools you used.');
  if(wordCount < 200) suggestions.push('Consider expanding the resume to include more details on projects and results.');
  if(skillsFound.includes('javascript') && !lower.includes('react')) suggestions.push('If experienced with frontend, mention frameworks like React or Next.js if applicable.');

  // simple summary (first 2 lines)
  const lines = text.split(/\r?\n/).map(l=>l.trim()).filter(Boolean);
  const summary = lines.slice(0,4).join(' | ');

  return {score, wordCount, skillsFound, suggestions, summary};
}

app.post('/analyze', (req, res) => {
  const { text } = req.body || {};
  if(!text){
    return res.status(400).json({ error: 'No text provided. Send JSON {"text":"..."} or use the demo UI.' });
  }
  const result = analyzeText(text);
  res.json(result);
});

app.get('/ping', (req,res)=>res.send('ok'));

const PORT = process.env.PORT || 3002;
app.listen(PORT, ()=>console.log(`Resume analyzer listening on ${PORT}`));
