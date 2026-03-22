const socket = io();

let inChat = false;
let isWaiting = false;
let typingTimeout = null;

const statusBox = document.getElementById('statusBox');
const chatBox = document.getElementById('chatBox');
const msgInput = document.getElementById('msgInput');
const sendBtn = document.getElementById('sendBtn');
const nextBtn = document.getElementById('nextBtn');
const typingIndicator = document.getElementById('typingIndicator');
const onlineCount = document.getElementById('onlineCount');

socket.on('onlineCount', (count) => {
  onlineCount.textContent = count;
});

socket.on('waiting', (msg) => {
  statusBox.textContent = msg;
  statusBox.style.color = '#fff';
  inChat = false;
  isWaiting = true;
  nextBtn.textContent = 'Stop';
  disableChat();
});

socket.on('matchFound', (msg) => {
  statusBox.textContent = msg;
  statusBox.style.color = '#00d2ff';
  inChat = true;
  isWaiting = false;
  nextBtn.textContent = 'Next';
  enableChat();
  chatBox.innerHTML = '';
  addSystemMessage("You're chatting with a random stranger. Say hi!");
});

socket.on('partnerLeft', (msg) => {
  statusBox.textContent = msg;
  statusBox.style.color = '#ffb347';
  inChat = false;
  addSystemMessage("Stranger has disconnected.");
  disableChat();
  typingIndicator.classList.add('hidden');
});

socket.on('receiveMessage', (msg) => {
  addMessage(msg, 'stranger');
  typingIndicator.classList.add('hidden');
});

socket.on('partnerTyping', () => {
  typingIndicator.classList.remove('hidden');
});
socket.on('partnerStoppedTyping', () => {
  typingIndicator.classList.add('hidden');
});

window.nextPerson = function() {
  if (isWaiting) {
    socket.emit('nextPerson');
    isWaiting = false;
    statusBox.textContent = "Search stopped. Press Start to meet a stranger.";
    nextBtn.textContent = 'Start';
    return;
  }
  
  if (inChat) {
    addSystemMessage("You disconnected.");
  }
  
  socket.emit('nextPerson'); 
  chatBox.innerHTML = '';
  socket.emit('startSearch');
}

window.sendMessage = function() {
  const msg = msgInput.value.trim();
  if (msg && inChat) {
    addMessage(msg, 'you');
    socket.emit('sendMessage', msg);
    msgInput.value = '';
    socket.emit('stopTyping');
  }
}

window.handleEnter = function(e) {
  if (e.key === 'Enter') sendMessage();
}

window.handleTyping = function() {
  if (!inChat) return;
  socket.emit('typing');
  clearTimeout(typingTimeout);
  typingTimeout = setTimeout(() => {
    socket.emit('stopTyping');
  }, 1000);
}

function addMessage(text, sender) {
  const div = document.createElement('div');
  div.className = 'msg ' + sender;
  div.textContent = text;
  chatBox.appendChild(div);
  chatBox.scrollTop = chatBox.scrollHeight;
}

function addSystemMessage(text) {
  const div = document.createElement('div');
  div.className = 'msg system';
  div.textContent = text;
  chatBox.appendChild(div);
  chatBox.scrollTop = chatBox.scrollHeight;
}

function enableChat() {
  msgInput.disabled = false;
  sendBtn.disabled = false;
  msgInput.focus();
}

function disableChat() {
  msgInput.disabled = true;
  msgInput.value = '';
  sendBtn.disabled = true;
}
