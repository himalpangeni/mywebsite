// Mobile nav toggle
const navToggle = document.getElementById('nav-toggle');
const nav = document.getElementById('nav');
if(navToggle && nav){
  navToggle.addEventListener('click', () => {
    const visible = nav.style.display === 'flex' || nav.style.display === 'block';
    nav.style.display = visible ? 'none' : 'flex';
  });
}

// Simple client-side contact form handler
function handleForm(e){
  e.preventDefault();
  const form = e.target;
  const data = new FormData(form);
  const name = data.get('name');
  const email = data.get('email');
  const message = data.get('message');

  // For now we just show a confirmation — replace with real endpoint if available
  alert(`Thanks ${name}! Your message has been captured. (Email: ${email})`);
  form.reset();
}

window.handleForm = handleForm;