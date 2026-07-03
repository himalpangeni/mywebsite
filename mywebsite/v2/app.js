/* ==============================================
   PORTFOLIO V2 — MODERN CREATIVE JS
   Himal Pangeni | Developer + Cyber Researcher
   ============================================== */

'use strict';

document.addEventListener('DOMContentLoaded', () => {
  // Intersection Observer for scroll animations (skills progress, reveal elements)
  const observerOptions = {
    threshold: 0.15,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver((entries, obs) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        
        // If it's a skill card, trigger progress bar animation
        if (entry.target.classList.contains('skill-card')) {
          const bar = entry.target.querySelector('.skill-bar-fill');
          if (bar) {
            const pct = entry.target.getAttribute('data-pct') || '0%';
            bar.style.width = pct;
          }
        }
        obs.unobserve(entry.target);
      }
    });
  }, observerOptions);

  // Observe skill cards
  document.querySelectorAll('.skill-card').forEach(card => {
    observer.observe(card);
  });

  // Observe other reveal sections/cards if any
  document.querySelectorAll('.proj-card').forEach(card => {
    card.classList.add('reveal');
    observer.observe(card);
  });

  // Contact form submission logic
  const form = document.getElementById('contact-form');
  const status = document.getElementById('form-status');

  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const name = document.getElementById('c-name').value.trim();
      const email = document.getElementById('c-email').value.trim();
      const message = document.getElementById('c-msg').value.trim();
      
      if (!name || !email || !message) {
        if (status) {
          status.textContent = '❌ All fields are required.';
          status.className = 'err';
        }
        return;
      }
      
      if (status) {
        status.textContent = '⚡ Transmitting secure payload...';
        status.className = '';
      }
      
      // Fictional response delay
      await new Promise(r => setTimeout(r, 1200));
      
      if (status) {
        status.textContent = '✔ Transmitted successfully. Himal will reply within 24h.';
        status.className = 'ok';
      }
      form.reset();
    });
  }
});
