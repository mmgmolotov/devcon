"use client";
import { useEffect } from 'react';

/**
 * Animation utility functions for DevCON UI components
 */

// Card hover animation effect
export function applyCardHoverEffect() {
  useEffect(() => {
    const cards = document.querySelectorAll('.card-hover-effect');

    const handleMouseMove = (e) => {
      const card = e.currentTarget;
      const rect = card.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      card.style.setProperty('--mouse-x', `${x}px`);
      card.style.setProperty('--mouse-y', `${y}px`);
    };

    cards.forEach(card => {
      card.addEventListener('mousemove', handleMouseMove);
    });

    return () => {
      cards.forEach(card => {
        card.removeEventListener('mousemove', handleMouseMove);
      });
    };
  }, []);
}

// Terminal text typing animation
export function typeText(element, text, speed = 50) {
  let i = 0;

  return new Promise((resolve) => {
    function type() {
      if (i < text.length) {
        element.innerHTML += text.charAt(i);
        i++;
        setTimeout(type, speed);
      } else {
        resolve();
      }
    }

    type();
  });
}

// Page transition animations
export function pageTransition(gsap) {
  return {
    // Page enter animation
    enter: (element) => {
      const tl = gsap.timeline();

      tl.fromTo(
        element,
        {
          opacity: 0,
          y: 20
        },
        {
          opacity: 1,
          y: 0,
          duration: 0.8,
          ease: 'power3.out'
        }
      );

      return tl;
    },

    // Page exit animation
    exit: (element) => {
      const tl = gsap.timeline();

      tl.to(
        element,
        {
          opacity: 0,
          y: -20,
          duration: 0.5,
          ease: 'power2.in'
        }
      );

      return tl;
    }
  };
}

// Staggered content reveal
export function staggeredReveal(gsap, elements, delay = 0.1) {
  gsap.fromTo(
    elements,
    {
      opacity: 0,
      y: 20
    },
    {
      opacity: 1,
      y: 0,
      stagger: delay,
      duration: 0.6,
      ease: 'power3.out'
    }
  );
}

// Floating animation for elements
export function applyFloatingAnimation() {
  useEffect(() => {
    const elements = document.querySelectorAll('.floating-element');

    elements.forEach((element, index) => {
      // Create slightly different durations for variety
      const duration = 4 + (index % 3);
      element.style.animation = `float ${duration}s ease-in-out infinite`;
    });

    return () => {
      elements.forEach(element => {
        element.style.animation = '';
      });
    };
  }, []);
}

// Matrix-style character scramble effect
export function characterScramble(element, finalText, duration = 2000) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()';
  const finalLength = finalText.length;
  let interval;
  let currentIteration = 0;
  const maxIterations = 10; // Number of scrambles before settling

  return new Promise((resolve) => {
    if (!element) {
      resolve();
      return;
    }

    clearInterval(interval);

    interval = setInterval(() => {
      currentIteration++;

      // Generate scrambled text
      let scrambledText = '';
      for (let i = 0; i < finalLength; i++) {
        // Gradually reveal correct characters as iterations progress
        if (i < (finalLength * (currentIteration / maxIterations))) {
          scrambledText += finalText[i];
        } else {
          scrambledText += characters.charAt(Math.floor(Math.random() * characters.length));
        }
      }

      element.innerText = scrambledText;

      // Settle on final text
      if (currentIteration >= maxIterations) {
        clearInterval(interval);
        element.innerText = finalText;
        resolve();
      }
    }, duration / maxIterations);
  });
}

// Terminal cursor blink effect
export function terminalCursorBlink() {
  useEffect(() => {
    const cursors = document.querySelectorAll('.terminal-cursor');

    cursors.forEach(cursor => {
      cursor.classList.add('blink');
    });

    return () => {
      cursors.forEach(cursor => {
        cursor.classList.remove('blink');
      });
    };
  }, []);
}

// CSS keyframes for use in styled-jsx
export const keyframes = {
  float: `
    @keyframes float {
      0% { transform: translateY(0px); }
      50% { transform: translateY(-10px); }
      100% { transform: translateY(0px); }
    }
  `,

  pulse: `
    @keyframes pulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.05); }
    }
  `,

  blink: `
    @keyframes blink {
      from, to { opacity: 1; }
      50% { opacity: 0; }
    }
  `,

  marquee: `
    @keyframes marquee {
      0% { transform: translateX(0); }
      100% { transform: translateX(-100%); }
    }
  `,

  glitch: `
    @keyframes glitch {
      0% {
        clip-path: inset(40% 0 61% 0);
        transform: translate(-2px, 2px);
      }
      20% {
        clip-path: inset(92% 0 1% 0);
        transform: translate(1px, 4px);
      }
      40% {
        clip-path: inset(43% 0 1% 0);
        transform: translate(3px, 1px);
      }
      60% {
        clip-path: inset(25% 0 58% 0);
        transform: translate(-5px, -3px);
      }
      80% {
        clip-path: inset(54% 0 7% 0);
        transform: translate(4px, -4px);
      }
      100% {
        clip-path: inset(58% 0 43% 0);
        transform: translate(-2px, 2px);
      }
    }
  `
};
