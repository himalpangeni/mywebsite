/* ==============================================
   PORTFOLIO V3 — MINIMAL ELEGANT JS
   Himal Pangeni | Developer + Cyber Researcher
   ============================================== */
'use strict';

document.addEventListener('DOMContentLoaded', () => {
  /* === SCROLL REVEAL === */
  const revealItems = document.querySelectorAll('.section, .hero-meta, .project-item, .skill-row');
  
  const io = new IntersectionObserver((entries) => {
    entries.forEach((entry, i) => {
      if (entry.isIntersecting) {
        // Stagger for lists
        const siblings = [...entry.target.parentElement.children];
        const idx = siblings.indexOf(entry.target);
        entry.target.style.transitionDelay = `${idx * 60}ms`;
        entry.target.classList.add('revealed');
        io.unobserve(entry.target);
      }
    });
  }, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });

  revealItems.forEach(el => {
    el.classList.add('will-reveal');
    io.observe(el);
  });

  /* === TYPING CURSOR on hero === */
  const h1 = document.querySelector('.hero h1');
  if (h1) {
    h1.style.borderRight = '2px solid currentColor';
    h1.style.animation = 'blink-cursor 1s step-end infinite';
    setTimeout(() => { h1.style.borderRight = 'none'; h1.style.animation = ''; }, 3500);
  }

  /* === NAV active highlight on scroll === */
  const sections = document.querySelectorAll('section[id], .hero[id]');
  const navLinks = document.querySelectorAll('.nav-links a');

  const navObserver = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        navLinks.forEach(a => {
          a.classList.remove('active-link');
          if (a.getAttribute('href') === `#${e.target.id}`) a.classList.add('active-link');
        });
      }
    });
  }, { threshold: 0.5 });

  sections.forEach(s => navObserver.observe(s));
});
