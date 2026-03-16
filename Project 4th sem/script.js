import { GoogleGenAI, Type } from "@google/genai";

const ItemStatus = {
  Lost: 'Lost',
  Found: 'Found',
  Claimed: 'Claimed',
};

// --- STATE MANAGEMENT ---
let allItems = [];
let pendingItems = [];
let messages = {};
let currentFilter = 'All';
let currentUserRole = 'user';
let imageFile = null;
let currentMessagingItemId = null;


// --- DOM ELEMENT SELECTORS ---
const itemGrid = document.getElementById('item-grid');
const loader = document.getElementById('loader');
const errorMessage = document.getElementById('error-message');
const noItemsMessage = document.getElementById('no-items-message');
const filterButtonsContainer = document.getElementById('filter-buttons');
const reportItemBtn = document.getElementById('report-item-btn');
const formModal = document.getElementById('form-modal');
const modalCloseBtn = document.getElementById('modal-close-btn');
const formCancelBtn = document.getElementById('form-cancel-btn');
const itemForm = document.getElementById('item-form');
const formSuccessMessage = document.getElementById('form-success-message');
const fileUploadInput = document.getElementById('file-upload');
const imagePreview = document.getElementById('image-preview');
const imagePreviewContainer = document.getElementById('image-preview-container');
const uploadPlaceholder = document.getElementById('upload-placeholder');
const dropZone = document.getElementById('drop-zone');
const roleSelect = document.getElementById('role-select');
const adminPanel = document.getElementById('admin-panel');
const pendingItemGrid = document.getElementById('pending-item-grid');
const noPendingItemsMessage = document.getElementById('no-pending-items-message');

// Messaging Modal Elements
const messagingModal = document.getElementById('messaging-modal');
const messagingModalCloseBtn = document.getElementById('messaging-modal-close-btn');
const messagingModalTitle = document.getElementById('messaging-modal-title');
const messageHistory = document.getElementById('message-history');
const messageForm = document.getElementById('message-form');
const messageInput = document.getElementById('message-input');


// --- LOCALSTORAGE PERSISTENCE ---
function saveStateToLocalStorage() {
    localStorage.setItem('lostAndFound_allItems', JSON.stringify(allItems));
    localStorage.setItem('lostAndFound_pendingItems', JSON.stringify(pendingItems));
    localStorage.setItem('lostAndFound_messages', JSON.stringify(messages));
}

function loadStateFromLocalStorage() {
    const savedAllItems = localStorage.getItem('lostAndFound_allItems');
    const savedPendingItems = localStorage.getItem('lostAndFound_pendingItems');
    const savedMessages = localStorage.getItem('lostAndFound_messages');

    if (savedAllItems) allItems = JSON.parse(savedAllItems);
    if (savedPendingItems) pendingItems = JSON.parse(savedPendingItems);
    if (savedMessages) messages = JSON.parse(savedMessages);

    return savedAllItems !== null;
}


// --- GEMINI API SERVICE ---
const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

async function generateInitialItems() {
  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: "Generate a list of 7 diverse and realistic lost and found items for a college campus. Include items like electronics, textbooks, personal belongings, etc. For each item, provide a title, description, status (either 'Lost' or 'Found'), date found/lost in YYYY-MM-DD format, a plausible campus location, and a fictional contact email.",
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.ARRAY,
          items: {
            type: Type.OBJECT,
            properties: {
              title: { type: Type.STRING },
              description: { type: Type.STRING },
              status: { type: Type.STRING, enum: [ItemStatus.Lost, ItemStatus.Found] },
              date: { type: Type.STRING },
              location: { type: Type.STRING },
              contact: { type: Type.STRING }
            },
            required: ["title", "description", "status", "date", "location", "contact"]
          },
        },
      },
    });

    const jsonString = response.text.trim();
    const generatedItems = JSON.parse(jsonString);

    return generatedItems.map((item, index) => ({
      ...item,
      id: `gemini-${Date.now()}-${index}`,
      imageUrl: `https://picsum.photos/seed/${encodeURIComponent(item.title)}/400/300`,
    }));

  } catch (error) {
    console.error("Error generating initial items with Gemini:", error);
    errorMessage.textContent = 'Failed to fetch items from Gemini. Displaying fallback data.';
    errorMessage.classList.remove('hidden');
    // Fallback to dummy data
    return [
        { id: 'fallback-1', title: 'Blue Hydro Flask', description: 'Covered in various stickers, including a national park one.', status: ItemStatus.Found, date: '2023-10-26', location: 'Library 2nd Floor', contact: 'student@example.edu', imageUrl: 'https://picsum.photos/seed/hydroflask/400/300' },
        { id: 'fallback-2', title: 'AirPods Pro Case', description: 'White case, no AirPods inside. A bit scratched on the back.', status: ItemStatus.Lost, date: '2023-10-25', location: 'Campus Gym', contact: 'student2@example.edu', imageUrl: 'https://picsum.photos/seed/airpods/400/300' },
        { id: 'fallback-3', title: 'Calculus Textbook', description: 'Introduction to Calculus, 3rd Edition. Has some highlighting in chapter 2.', status: ItemStatus.Found, date: '2023-10-27', location: 'Lecture Hall B', contact: 'finder@example.edu', imageUrl: 'https://picsum.photos/seed/textbook/400/300' },
    ];
  }
}

// --- RENDERING LOGIC ---

function createActionButtons(item) {
    if (item.status === ItemStatus.Claimed) return '';
    return `
     <div class="card-actions">
        <button class="card-action-btn contact-btn" data-item-id="${item.id}" data-item-title="${item.title}">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>
            Contact
        </button>
        <button class="card-action-btn claim-btn" data-item-id="${item.id}">
             <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            Mark as Claimed
        </button>
    </div>
    `;
}

function createItemCard(item) {
    const isClaimed = item.status === ItemStatus.Claimed;
    return `
    <div class="item-card status-${item.status}" aria-labelledby="item-title-${item.id}">
      ${isClaimed ? '<div class="claimed-overlay"><span class="claimed-text">CLAIMED</span></div>' : ''}
      <img src="${item.imageUrl}" alt="${item.title}">
      <div class="card-content">
        <div class="card-header">
          <h3 id="item-title-${item.id}">${item.title}</h3>
          <span class="status-badge status-${item.status}">${item.status}</span>
        </div>
        <p class="card-description">${item.description}</p>
        <div class="card-details">
          <div class="detail-item">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
            <span>${item.date}</span>
          </div>
          <div class="detail-item">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
            <span>${item.location}</span>
          </div>
        </div>
        ${createActionButtons(item)}
      </div>
    </div>
    `;
}


function createPendingItemCard(item) {
    return `
    <div class="pending-item-card" id="pending-item-${item.id}">
        <div class="pending-item-header">
            <h4>${item.title}</h4>
            <span class="status-badge status-${item.status}">${item.status}</span>
        </div>
        <p class="pending-item-info"><strong>Location:</strong> ${item.location}</p>
        <p class="pending-item-info"><strong>Contact:</strong> ${item.contact}</p>
        <div class="pending-item-actions">
            <button class="admin-btn approve-btn" data-item-id="${item.id}">Approve</button>
            <button class="admin-btn reject-btn" data-item-id="${item.id}">Reject</button>
        </div>
    </div>
    `;
}

function renderItems() {
    itemGrid.innerHTML = '';
    const filteredItems = currentFilter === 'All' 
        ? allItems 
        : allItems.filter(item => item.status === currentFilter);
    
    if (filteredItems.length > 0) {
        itemGrid.innerHTML = filteredItems.map(createItemCard).join('');
        noItemsMessage.classList.add('hidden');
    } else {
        noItemsMessage.classList.remove('hidden');
    }
}

function renderAdminPanel() {
    if (pendingItems.length > 0) {
        pendingItemGrid.innerHTML = pendingItems.map(createPendingItemCard).join('');
        noPendingItemsMessage.classList.add('hidden');
        pendingItemGrid.classList.remove('hidden');
    } else {
        pendingItemGrid.classList.add('hidden');
        noPendingItemsMessage.classList.remove('hidden');
    }
}

function renderAll() {
    renderItems();
    if(currentUserRole === 'admin') {
        renderAdminPanel();
    }
}

// --- EVENT HANDLERS ---
function handleFilterClick(e) {
    if (e.target.tagName !== 'BUTTON') return;
    currentFilter = e.target.dataset.filter;
    document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
    e.target.classList.add('active');
    renderItems();
}

function handleImageUpload(file) {
    if (file && file.type.startsWith('image/')) {
        imageFile = file;
        const reader = new FileReader();
        reader.onload = (e) => {
            imagePreview.src = e.target.result;
            imagePreviewContainer.classList.remove('hidden');
            uploadPlaceholder.classList.add('hidden');
        };
        reader.readAsDataURL(file);
    }
}

function resetForm() {
    itemForm.reset();
    imageFile = null;
    imagePreview.src = '#';
    imagePreviewContainer.classList.add('hidden');
    uploadPlaceholder.classList.remove('hidden');
    formSuccessMessage.classList.add('hidden');
}

function handleFormSubmit(e) {
    e.preventDefault();
    const formData = new FormData(itemForm);
    
    const newItem = {
        id: `user-${Date.now()}`,
        title: formData.get('title'),
        description: formData.get('description'),
        status: formData.get('status'),
        date: new Date().toISOString().split('T')[0],
        location: formData.get('location'),
        contact: formData.get('contact'),
        imageUrl: imageFile ? URL.createObjectURL(imageFile) : `https://picsum.photos/seed/${encodeURIComponent(formData.get('title'))}/400/300`
    };

    pendingItems.unshift(newItem);
    saveStateToLocalStorage();
    renderAdminPanel();

    formSuccessMessage.classList.remove('hidden');
    setTimeout(() => {
        closeModal(formModal, resetForm);
    }, 2000);
}

function handleRoleChange(e) {
    currentUserRole = e.target.value;
    adminPanel.classList.toggle('hidden', currentUserRole !== 'admin');
    if (currentUserRole === 'admin') {
        renderAdminPanel();
    }
}

function handleAdminAction(e) {
    const target = e.target;
    const itemId = target.dataset.itemId;
    if (!itemId) return;

    const itemIndex = pendingItems.findIndex(item => item.id === itemId);
    if (itemIndex === -1) return;
    
    if (target.classList.contains('approve-btn')) {
        const [approvedItem] = pendingItems.splice(itemIndex, 1);
        allItems.unshift(approvedItem);
    } else if (target.classList.contains('reject-btn')) {
        pendingItems.splice(itemIndex, 1);
    }

    saveStateToLocalStorage();
    renderAll();
}

function handleCardAction(e) {
    const target = e.target.closest('button');
    if (!target) return;

    const itemId = target.dataset.itemId;
    const item = allItems.find(i => i.id === itemId);
    if (!item) return;

    if (target.classList.contains('claim-btn')) {
        item.status = ItemStatus.Claimed;
        saveStateToLocalStorage();
        renderItems();
    } else if (target.classList.contains('contact-btn')) {
        openMessagingModal(itemId);
    }
}


// --- MODAL CONTROLS ---
function showModal(modal) {
    modal.classList.remove('hidden');
}

function closeModal(modal, onclose) {
    modal.classList.add('hidden');
    if (onclose) onclose();
}

// --- MESSAGING LOGIC ---
function openMessagingModal(itemId) {
    currentMessagingItemId = itemId;
    const item = allItems.find(i => i.id === itemId);
    messagingModalTitle.textContent = `Message about: ${item.title}`;
    
    if (!messages[itemId]) {
        messages[itemId] = [];
    }

    renderMessages(itemId);
    showModal(messagingModal);
}

function renderMessages(itemId) {
    messageHistory.innerHTML = '';
    const conversation = messages[itemId] || [];
    conversation.forEach(msg => {
        const bubble = document.createElement('div');
        bubble.classList.add('message-bubble', msg.sender);
        bubble.textContent = msg.text;
        messageHistory.appendChild(bubble);
    });
    messageHistory.scrollTop = messageHistory.scrollHeight;
}

function handleMessageSubmit(e) {
    e.preventDefault();
    const text = messageInput.value.trim();
    if (text && currentMessagingItemId) {
        messages[currentMessagingItemId].push({ text, sender: 'sent' });
        // Simulate a reply for demonstration
        setTimeout(() => {
            messages[currentMessagingItemId].push({ text: "Thanks, I'll get back to you soon!", sender: 'received' });
            saveStateToLocalStorage();
            renderMessages(currentMessagingItemId);
        }, 1000);
        
        saveStateToLocalStorage();
        renderMessages(currentMessagingItemId);
        messageInput.value = '';
    }
}


// --- INITIALIZATION ---
async function main() {
    try {
        const dataLoaded = loadStateFromLocalStorage();
        if (!dataLoaded || allItems.length === 0) {
            const initialItems = await generateInitialItems();
            allItems = initialItems;
            saveStateToLocalStorage();
        }
        renderAll();
    } catch (e) {
        errorMessage.textContent = 'A critical error occurred. Please refresh the page.';
        errorMessage.classList.remove('hidden');
        console.error(e);
    } finally {
        loader.classList.add('hidden');
    }
}

// --- EVENT LISTENERS ---
document.addEventListener('DOMContentLoaded', main);
filterButtonsContainer.addEventListener('click', handleFilterClick);
reportItemBtn.addEventListener('click', () => showModal(formModal));
modalCloseBtn.addEventListener('click', () => closeModal(formModal, resetForm));
formCancelBtn.addEventListener('click', () => closeModal(formModal, resetForm));
formModal.addEventListener('click', (e) => {
    if (e.target === formModal) closeModal(formModal, resetForm);
});
itemForm.addEventListener('submit', handleFormSubmit);

roleSelect.addEventListener('change', handleRoleChange);
pendingItemGrid.addEventListener('click', handleAdminAction);
itemGrid.addEventListener('click', handleCardAction);

// Messaging modal listeners
messagingModalCloseBtn.addEventListener('click', () => closeModal(messagingModal, () => currentMessagingItemId = null));
messagingModal.addEventListener('click', (e) => {
    if (e.target === messagingModal) closeModal(messagingModal, () => currentMessagingItemId = null);
});
messageForm.addEventListener('submit', handleMessageSubmit);


// Drag and drop for image upload
dropZone.addEventListener('dragover', (e) => { e.preventDefault(); dropZone.style.borderColor = 'var(--primary-color)'; });
dropZone.addEventListener('dragleave', () => { dropZone.style.borderColor = 'var(--border-color)'; });
dropZone.addEventListener('drop', (e) => { e.preventDefault(); dropZone.style.borderColor = 'var(--border-color)'; handleImageUpload(e.dataTransfer.files[0]); });
fileUploadInput.addEventListener('change', (e) => handleImageUpload(e.target.files[0]));
dropZone.addEventListener('click', () => fileUploadInput.click());