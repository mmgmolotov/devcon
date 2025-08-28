"use client";
import React, { useEffect, useRef, useState } from "react";
import {
  FaReact,
  FaNodeJs,
  FaPython,
  FaDocker,
  FaHtml5,
  FaCss3Alt,
  FaGitAlt,
  FaAws,
} from "react-icons/fa";
import {
  SiTypescript,
  SiJavascript,
  SiTailwindcss,
  SiRedux,
  SiNextdotjs,
  SiMongodb,
  SiPostgresql,
  SiGraphql,
} from "react-icons/si";

// Main App component that brings everything together
function App() {
  // --- Reusable Icon Components ---
  const marqueeTrackRef = useRef(null);
  const CollaborateIcon = () => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="w-10 h-10 mb-4 text-green-400"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M12 21a9 9 0 01-9-9 9 9 0 019-9 9 9 0 019 9 9 9 0 01-9 9z"
      />
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M9 10h6m-3 0v6m-3-3h.01M15 13h.01"
      />
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M21 12a9 9 0 00-9-9"
      />
    </svg>
  );

  const ShareCodeIcon = () => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="w-10 h-10 mb-4 text-green-400"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M6.75 7.5l3 2.25-3 2.25m8.5 0l3-2.25-3-2.25"
      />
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 16.5V7.5" />
    </svg>
  );

  const FindProjectsIcon = () => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="w-10 h-10 mb-4 text-green-400"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M15.59 14.37a6 6 0 01-5.84 7.38v-4.82m5.84-2.56a12.022 12.022 0 00-11.66 0m11.66 0l-1.12-2.24a12.022 12.022 0 0111.66 0l-1.12 2.24zM12 12v9m0 0a9 9 0 01-9-9m9 9a9 9 0 009-9"
      />
    </svg>
  );

  // --- Header Component ---
  const Header = ({ progress }) => {
    return (
      <header className="fixed top-0 left-0 right-0 z-50 bg-[#1e1e1e]/80 backdrop-blur-sm border-b border-gray-700">
        <div className="container mx-auto px-4 sm:px-8 flex justify-between items-center h-20">
          <div className="text-2xl font-mono text-green-400 code-text-glow">
            // DevCON
          </div>
          <nav className="hidden md:flex items-center gap-8 font-mono">
            <a
              href="#features"
              className="text-gray-400 hover:text-green-400 transition-colors"
            >
              Features
            </a>
            <a
              href="#testimonials"
              className="text-gray-400 hover:text-green-400 transition-colors"
            >
              Testimonials
            </a>
            <a
              href="#projects"
              className="text-gray-400 hover:text-green-400 transition-colors"
            >
              Projects
            </a>
            <a
              href="#tech-stack"
              className="text-gray-400 hover:text-green-400 transition-colors"
            >
              Stack
            </a>
          </nav>
          <div className="flex gap-3">
            <a
              href="/auth/login"
              className="px-4 py-2 bg-green-500 text-black font-mono font-bold rounded hover:bg-green-400 transition-colors code-button-glow"
            >
              Login
            </a>
            <a
              href="/auth/register"
              className="px-4 py-2 bg-gray-700/70 text-green-400 font-mono font-bold rounded border border-green-500 hover:bg-gray-700 transition-colors"
            >
              Register
            </a>
          </div>
        </div>
      </header>
    );
  };

  // --- Interactive Particle Background Component ---
  const ParticleBackground = () => {
    const mountRef = useRef(null);

    useEffect(() => {
      // Check if we're in a browser environment
      if (typeof window === "undefined") return;

      let three, scene, camera, renderer, particles;
      let reqId;

      const init = () => {
        three = window.THREE;
        if (!three) {
          console.log("Three.js not loaded yet");
          return;
        }

        const container = mountRef.current;
        scene = new three.Scene();
        camera = new three.PerspectiveCamera(
          75,
          container.clientWidth / container.clientHeight,
          0.1,
          1000,
        );
        camera.position.z = 10;

        renderer = new three.WebGLRenderer({ antialias: true, alpha: true });
        renderer.setSize(container.clientWidth, container.clientHeight);
        container.appendChild(renderer.domElement);

        const particleCount = 5000;
        const positions = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
          positions[i * 3] = (Math.random() - 0.5) * 30;
          positions[i * 3 + 1] = (Math.random() - 0.5) * 30;
          positions[i * 3 + 2] = (Math.random() - 0.5) * 30;
        }

        const geometry = new three.BufferGeometry();
        geometry.setAttribute(
          "position",
          new three.BufferAttribute(positions, 3),
        );

        const material = new three.PointsMaterial({
          color: 0x39ff14, // Terminal Green
          size: 0.02,
          transparent: true,
          opacity: 0.7,
        });

        particles = new three.Points(geometry, material);
        scene.add(particles);

        const onResize = () => {
          camera.aspect = container.clientWidth / container.clientHeight;
          camera.updateProjectionMatrix();
          renderer.setSize(container.clientWidth, container.clientHeight);
        };
        window.addEventListener("resize", onResize);

        const clock = new three.Clock();
        const animate = () => {
          reqId = requestAnimationFrame(animate);
          const elapsedTime = clock.getElapsedTime();

          particles.rotation.y = elapsedTime * 0.05;

          renderer.render(scene, camera);
        };
        animate();

        return () => {
          cancelAnimationFrame(reqId);
          window.removeEventListener("resize", onResize);
          if (container && renderer.domElement) {
            container.removeChild(renderer.domElement);
          }
        };
      };

      // Only attempt to load scripts in browser environment
      if (typeof window !== "undefined" && typeof document !== "undefined") {
        const threeSrc =
          "https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js";
        if (!document.querySelector(`script[src="${threeSrc}"]`)) {
          const script = document.createElement("script");
          script.src = threeSrc;
          script.onload = init;
          document.body.appendChild(script);
        } else {
          init();
        }
      }
    }, []);

    return (
      <div ref={mountRef} className="absolute top-0 left-0 w-full h-full z-0" />
    );
  };

  // --- Animated Code Snippet Component ---
  const CodeSnippet = ({ codeLines }) => {
    const codeRef = useRef(null);

    useEffect(() => {
      const codeEl = codeRef.current;
      let tl;
      if (window.gsap && window.TextPlugin) {
        tl = window.gsap.timeline({
          scrollTrigger: {
            trigger: codeEl,
            start: "top 85%",
            toggleActions: "play none none none",
          },
        });

        codeLines.forEach((line, index) => {
          const elId = `line-${Math.random().toString(36).substr(2, 9)}`;
          codeEl.innerHTML += `<span id="${elId}"></span><br/>`;
          tl.to(`#${elId}`, {
            duration: line.length * 0.03,
            text: line,
            ease: "none",
          });
        });
      }
      return () => tl && tl.kill();
    }, [codeLines]);

    return (
      <div className="bg-[#1a1a1a] p-3 rounded-md mt-4 text-left text-sm font-mono border border-gray-700">
        <div className="flex items-center gap-1.5 mb-2">
          <div className="w-3 h-3 rounded-full bg-red-500"></div>
          <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
          <div className="w-3 h-3 rounded-full bg-green-500"></div>
        </div>
        <code
          ref={codeRef}
          className="text-green-400 whitespace-pre-wrap"
        ></code>
      </div>
    );
  };

  // --- Footer Component ---
  const Footer = () => {
    return (
      <footer className="w-full bg-[#1e1e1e] border-t border-gray-700 mt-28">
        <div className="container mx-auto px-4 sm:px-8 py-8 flex flex-col sm:flex-row justify-between items-center text-center sm:text-left">
          <p className="font-mono text-gray-400">
            &copy; 2025 DevCON. All rights reserved.
          </p>
          <div className="flex flex-col mt-4 sm:mt-0">
            <div className="text-xs text-gray-500 mb-2 font-mono">
              Keyboard Shortcuts
            </div>
            <div className="flex flex-wrap gap-2 justify-center sm:justify-start">
              <div className="bg-gray-800 px-2 py-1 rounded text-xs flex items-center">
                <kbd className="px-1 bg-black rounded border border-gray-700 mr-1">
                  Alt+C
                </kbd>
                <span className="text-green-400">Collaborate</span>
              </div>
              <div className="bg-gray-800 px-2 py-1 rounded text-xs flex items-center">
                <kbd className="px-1 bg-black rounded border border-gray-700 mr-1">
                  Alt+S
                </kbd>
                <span className="text-green-400">Stack</span>
              </div>
              <div className="bg-gray-800 px-2 py-1 rounded text-xs flex items-center">
                <kbd className="px-1 bg-black rounded border border-gray-700 mr-1">
                  Ctrl+L
                </kbd>
                <span className="text-green-400">Login</span>
              </div>
            </div>
          </div>
          <div className="flex gap-4 mt-4 sm:mt-0">
            <a
              href="https://github.com"
              className="text-gray-400 hover:text-green-400 transition-colors"
              target="_blank"
              rel="noopener noreferrer"
            >
              <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                <path
                  fillRule="evenodd"
                  d="M12 2C6.477 2 2 6.477 2 12c0 4.418 2.865 8.168 6.839 9.49.5.092.682-.217.682-.482 0-.237-.009-.868-.014-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.031-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.03 1.595 1.03 2.688 0 3.848-2.338 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.001 10.001 0 0022 12c0-5.523-4.477-10-10-10z"
                  clipRule="evenodd"
                />
              </svg>
            </a>
            <a
              href="https://twitter.com"
              className="text-gray-400 hover:text-green-400 transition-colors"
              target="_blank"
              rel="noopener noreferrer"
            >
              <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
              </svg>
            </a>
          </div>
        </div>

        <div className="w-full border-t border-gray-800 mt-4">
          <div className="container mx-auto py-4 px-4 sm:px-8 text-center text-xs text-gray-600">
            <p>
              DevCON is a developer community platform. Made with 💚 for
              developers.
            </p>
          </div>
        </div>
      </footer>
    );
  };

  // --- Main Home Component ---
  const Home = () => {
    const main = useRef(null);
    const progressRef = useRef(null);

    useEffect(() => {
      // Check if we're in a browser environment
      if (typeof window === "undefined" || typeof document === "undefined")
        return;

      const fontLink = document.createElement("link");
      fontLink.href =
        "https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@400;700&family=Inter:wght@400;700&display=swap";
      fontLink.rel = "stylesheet";
      document.head.appendChild(fontLink);

      let ctx;

      const loadScripts = async () => {
        // Only load scripts in browser environment
        if (typeof window === "undefined" || typeof document === "undefined")
          return;

        const scripts = [
          "https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js",
          "https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/ScrollTrigger.min.js",
          "https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/TextPlugin.min.js",
        ];

        const addScript = (src) =>
          new Promise((resolve, reject) => {
            if (document.querySelector(`script[src="${src}"]`)) {
              resolve();
              return;
            }
            const script = document.createElement("script");
            script.src = src;
            script.onload = resolve;
            script.onerror = reject;
            document.body.appendChild(script);
          });

        try {
          await Promise.all(scripts.map(addScript));

          const gsap = window.gsap;
          if (!gsap) {
            console.log("GSAP not available yet, will retry.");
            // Retry after a short delay
            setTimeout(loadScripts, 500);
            return;
          }
          gsap.registerPlugin(window.ScrollTrigger, window.TextPlugin);

          ctx = gsap.context(() => {
            // Scroll progress bar animation
            gsap.to(progressRef.current, {
              scaleX: 1,
              ease: "none",
              scrollTrigger: {
                scrub: 0.3,
              },
            });

            gsap.fromTo(
              "header",
              { y: -100, opacity: 0 },
              { y: 0, opacity: 1, duration: 1, ease: "power3.out", delay: 0.2 },
            );

            gsap.fromTo(
              ".hero-element",
              { opacity: 0, y: 20 },
              {
                opacity: 1,
                y: 0,
                duration: 1.2,
                stagger: 0.2,
                ease: "power3.out",
                delay: 1,
              },
            );

            // Add keyboard shortcuts - only in browser environment
            if (typeof document !== "undefined") {
              document.addEventListener("keydown", function (e) {
                // Alt+C for Collaborate
                if (e.altKey && e.key === "c") {
                  document
                    .querySelector(".features-section")
                    .scrollIntoView({ behavior: "smooth" });
                }
                // Alt+S for Stack
                if (e.altKey && e.key === "s") {
                  document
                    .querySelector("#tech-stack")
                    .scrollIntoView({ behavior: "smooth" });
                }
                // Ctrl+L for Login
                if (e.ctrlKey && e.key === "l") {
                  window.location.href = "/auth/login";
                }
              });
            }
            gsap.fromTo(
              ".hero-line",
              { scaleX: 0 },
              { scaleX: 1, duration: 1, ease: "power3.out", delay: 1.5 },
            );

            const words = ["Connect", "Collaborate", "Code"];
            let masterTl = gsap.timeline({ repeat: -1 });

            words.forEach((word) => {
              let tl = gsap.timeline({ repeat: 1, yoyo: true, repeatDelay: 1 });
              tl.to(".animated-text", {
                duration: word.length * 0.1,
                text: word,
                ease: "none",
              });
              masterTl.add(tl);
            });

            const sections = [
              ".features-section",
              ".testimonials-section",
              ".projects-section",
              ".tech-stack-section",
            ];
            sections.forEach((selector) => {
              gsap.fromTo(
                `${selector} .section-title, ${selector} .section-line`,
                { opacity: 0, y: -20 },
                {
                  opacity: 1,
                  y: 0,
                  duration: 0.8,
                  stagger: 0.2,
                  ease: "power3.out",
                  scrollTrigger: { trigger: selector, start: "top 80%" },
                },
              );
              gsap.fromTo(
                `${selector} .animated-card`,
                { opacity: 0, y: 50, scale: 0.95 },
                {
                  opacity: 1,
                  y: 0,
                  scale: 1,
                  duration: 0.8,
                  stagger: 0.2,
                  ease: "power3.out",
                  scrollTrigger: {
                    trigger: `${selector} .card-container`,
                    start: "top 85%",
                  },
                },
              );
            });

            // Animate only the icons row (marquee-track) with GSAP, edge-to-edge
            if (marqueeTrackRef.current) {
              const track = marqueeTrackRef.current;
              const parent = track.parentElement;
              const trackWidth = track.scrollWidth / 2;
              const parentWidth = parent.offsetWidth;
              gsap.set(track, { x: 0 });
              gsap.to(track, {
                x: `-=${trackWidth}`,
                duration: 18,
                ease: "linear",
                repeat: -1,
                modifiers: {
                  x: (x) => {
                    const val = parseFloat(x) % trackWidth;
                    return `${val}px`;
                  },
                },
              });
            }
          }, main);
        } catch (error) {
          console.error("Failed to load scripts:", error);
        }
      };

      loadScripts();

      return () => {
        if (ctx) ctx.revert();
        if (
          typeof document !== "undefined" &&
          document.head &&
          document.head.contains(fontLink)
        )
          document.head.removeChild(fontLink);
      };
    }, []);

    const projects = [
      {
        title: "Open Source Chat App",
        desc: "Real-time chat built with Next.js, Tailwind, and Supabase.",
        code: [
          "import { createClient } from '@supabase/supabase-js';",
          "const supabase = createClient(url, key);",
        ],
      },
      {
        title: "Dev Portfolio Builder",
        desc: "Create and share your developer portfolio with live previews.",
        code: [
          "function Portfolio({ user }) {",
          "  return <div>{user.name}</div>;",
          "}",
        ],
      },
      {
        title: "API Playground",
        desc: "Test, share, and document APIs with a collaborative playground.",
        code: [
          "fetch('https://api.devcon.com/v1/users')",
          "  .then(res => res.json())",
          "  .then(data => console.log(data));",
        ],
      },
    ];

    const techStack = [
      {
        name: "React",
        icon: <FaReact className="w-12 h-12 text-[#61DAFB] tech-icon" />,
      },
      {
        name: "Node.js",
        icon: <FaNodeJs className="w-12 h-12 text-[#8CC84B] tech-icon" />,
      },
      {
        name: "Python",
        icon: <FaPython className="w-12 h-12 text-[#306998] tech-icon" />,
      },
      {
        name: "Docker",
        icon: <FaDocker className="w-12 h-12 text-[#0db7ed] tech-icon" />,
      },
      {
        name: "TypeScript",
        icon: <SiTypescript className="w-12 h-12 text-[#3178c6] tech-icon" />,
      },
      {
        name: "JavaScript",
        icon: <SiJavascript className="w-12 h-12 text-[#f7df1e] tech-icon" />,
      },
      {
        name: "HTML5",
        icon: <FaHtml5 className="w-12 h-12 text-[#e34f26] tech-icon" />,
      },
      {
        name: "CSS3",
        icon: <FaCss3Alt className="w-12 h-12 text-[#1572b6] tech-icon" />,
      },
      {
        name: "Tailwind CSS",
        icon: <SiTailwindcss className="w-12 h-12 text-[#38bdf8] tech-icon" />,
      },
      {
        name: "Redux",
        icon: <SiRedux className="w-12 h-12 text-[#764abc] tech-icon" />,
      },
      {
        name: "Next.js",
        icon: (
          <SiNextdotjs className="w-12 h-12 text-black dark:text-white tech-icon" />
        ),
      },
      {
        name: "Git",
        icon: <FaGitAlt className="w-12 h-12 text-[#f05032] tech-icon" />,
      },
      {
        name: "MongoDB",
        icon: <SiMongodb className="w-12 h-12 text-[#47A248] tech-icon" />,
      },
      {
        name: "PostgreSQL",
        icon: <SiPostgresql className="w-12 h-12 text-[#336791] tech-icon" />,
      },
      {
        name: "GraphQL",
        icon: <SiGraphql className="w-12 h-12 text-[#e10098] tech-icon" />,
      },
      {
        name: "AWS",
        icon: <FaAws className="w-12 h-12 text-[#FF9900] tech-icon" />,
      },
    ];
    // Duplicate icons for seamless marquee
    const techStackMarquee = [...techStack, ...techStack];

    return (
      <>
        <Header progress={progressRef} />
        <style>{`
          .font-body { font-family: 'Inter', sans-serif; }
          .font-mono { font-family: 'Roboto Mono', monospace; }
          .code-text-glow { text-shadow: 0 0 8px rgba(57, 255, 20, 0.5); }
          .code-button-glow { box-shadow: 0 0 12px rgba(57, 255, 20, 0.4); }
          .hero-headline { min-height: 2.4em; }
          .blinking-cursor {
            animation: blink 1s step-end infinite;
          }
          @keyframes blink {
            from, to { color: transparent; }
            50% { color: #39ff14; }
          }
          .animated-text-container {
            display: inline-block;
            min-width: 11ch; /* Adjust this value based on the longest word ("Collaborate") */
            text-align: left;
          }
          .card-hover-effect {
            position: relative;
            overflow: hidden;
          }
          .card-hover-effect::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            background: radial-gradient(circle at var(--mouse-x) var(--mouse-y), rgba(57, 255, 20, 0.25), transparent 40%);
            opacity: 0;
            transition: opacity 0.3s;
          }
          .card-hover-effect:hover::before {
            opacity: 1;
          }

          /* Hide Scrollbar */
          ::-webkit-scrollbar {
            display: none;
          }
          -ms-overflow-style: none; /* IE and Edge */
          scrollbar-width: none; /* Firefox */
          .animated-card {
            transition: transform 0.3s ease, box-shadow 0.3s ease, border-color 0.3s ease;
          }
          .animated-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 10px 25px -5px rgba(57, 255, 20, 0.3);
          }
          @keyframes float {
            0% { transform: translateY(0px); }
            50% { transform: translateY(-10px); }
            100% { transform: translateY(0px); }
          }
          .floating-element {
            animation: float 6s ease-in-out infinite;
          }
          .keyboard-shortcut {
            position: absolute;
            bottom: 5px;
            right: 8px;
            font-size: 0.65rem;
            color: rgba(255, 255, 255, 0.4);
            background: rgba(0, 0, 0, 0.3);
            padding: 2px 5px;
            border-radius: 3px;
            border: 1px solid rgba(255, 255, 255, 0.1);
          }
        `}</style>
        <div
          ref={main}
          className="min-h-screen bg-[#1e1e1e] text-gray-300 font-body overflow-x-hidden"
        >
          <div className="absolute top-0 left-0 w-full h-full bg-grid-pattern opacity-10"></div>

          <div className="relative z-10 flex flex-col items-center justify-center pb-24">
            {/* Hero Section */}
            <section className="hero-section w-full h-screen px-4 sm:px-8 flex flex-col items-center justify-center text-center">
              <ParticleBackground />
              <div className="relative z-10 max-w-4xl mx-auto">
                <h1 className="hero-headline text-4xl sm:text-6xl leading-tight text-green-400 font-mono code-text-glow mb-4">
                  DevCON:{" "}
                  <div className="animated-text-container">
                    <span className="animated-text"></span>
                    <span className="blinking-cursor">|</span>
                  </div>
                </h1>
                <div className="hero-line h-1 w-32 mx-auto mb-6 bg-green-500"></div>
                <p className="hero-element mt-4 text-lg sm:text-xl text-gray-400 max-w-2xl mx-auto">
                  Join a global community of developers. Build projects, share
                  code, and grow together.
                </p>
                <div className="hero-element mt-8 flex flex-col sm:flex-row justify-center gap-4">
                  <a
                    href="/auth/login"
                    className="px-8 py-3 bg-gray-700/50 text-green-400 rounded font-mono font-bold border-2 border-green-500 hover:bg-green-500 hover:text-black transition-all"
                  >
                    Login via Terminal
                  </a>
                  <a
                    href="/auth/register"
                    className="px-8 py-3 bg-black/30 text-green-400 rounded font-mono font-bold border-2 border-green-400 hover:bg-green-400/20 transition-all"
                  >
                    Register
                  </a>
                </div>
              </div>
            </section>

            {/* Features Section */}
            <section
              id="features"
              className="features-section mt-20 w-full flex flex-col items-center px-4 sm:px-8 scroll-mt-20"
            >
              <h2 className="section-title text-4xl font-bold mb-4 text-center font-mono">
                <span className="text-orange-400">Why</span>
                <span className="text-gray-400">.</span>
                <span className="text-blue-400">DevCON</span>
                <span className="text-gray-400">()</span>
              </h2>
              <div className="section-line h-1 w-24 mx-auto mb-12 bg-gray-700"></div>
              <div className="card-container grid gap-8 grid-cols-1 md:grid-cols-3 w-full max-w-6xl">
                {[
                  {
                    icon: <CollaborateIcon />,
                    title: "Collaborate",
                    desc: "Work with developers worldwide on open source and private projects.",
                  },
                  {
                    icon: <ShareCodeIcon />,
                    title: "Share Code",
                    desc: "Easily share code snippets, ideas, and solutions with the community.",
                  },
                  {
                    icon: <FindProjectsIcon />,
                    title: "Find Projects",
                    desc: "Discover interesting projects and join teams that match your skills.",
                  },
                ].map((feature) => (
                  <div
                    key={feature.title}
                    className={`animated-card card-hover-effect bg-[#252526] border border-gray-700 rounded-lg p-8 flex flex-col items-center text-center relative`}
                  >
                    <div className="floating-element">{feature.icon}</div>
                    <h3 className="text-xl font-semibold mb-2 font-mono text-orange-400">
                      {feature.title}
                    </h3>
                    <p className="text-gray-400">{feature.desc}</p>
                    <span className="keyboard-shortcut">
                      Alt+{feature.title.charAt(0)}
                    </span>
                  </div>
                ))}
              </div>
            </section>

            {/* Testimonials Section */}
            <section
              id="testimonials"
              className="testimonials-section mt-28 w-full flex flex-col items-center px-4 sm:px-8 scroll-mt-20"
            >
              <h2 className="section-title text-4xl font-bold mb-4 text-center font-mono">
                <span className="text-orange-400">What</span>
                <span className="text-gray-400">.</span>
                <span className="text-blue-400">DevelopersSay</span>
                <span className="text-gray-400">()</span>
              </h2>
              <div className="section-line h-1 w-24 mx-auto mb-12 bg-gray-700"></div>
              <div className="card-container grid gap-8 grid-cols-1 md:grid-cols-3 w-full max-w-6xl">
                {[
                  {
                    avatar: "https://placehold.co/64x64/1e1e1e/39ff14?text=A",
                    quote:
                      "DevCON helped me find collaborators for my open source project. The theme is 🔥!",
                    name: "Alex, Fullstack Dev",
                  },
                  {
                    avatar: "https://placehold.co/64x64/1e1e1e/39ff14?text=P",
                    quote:
                      "The project showcase is a game changer. I love sharing my work and getting feedback!",
                    name: "Priya, Frontend Engineer",
                  },
                  {
                    avatar: "https://placehold.co/64x64/1e1e1e/39ff14?text=S",
                    quote:
                      "DevCON's community is super supportive. The UI makes me want to code more!",
                    name: "Sam, Backend Architect",
                  },
                ].map((t) => (
                  <div
                    key={t.name}
                    className={`animated-card card-hover-effect bg-[#252526] border border-gray-700 rounded-lg p-8 flex flex-col items-center text-center overflow-hidden group`}
                  >
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-green-400 to-blue-500 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300"></div>
                    <img
                      src={t.avatar}
                      alt="Dev Avatar"
                      className="w-16 h-16 rounded-full mb-4 border-2 border-green-400 transition-transform group-hover:scale-110 duration-300"
                    />
                    <p className="text-gray-400 mb-4 italic">
                      &quot;<span className="text-green-400">{t.quote}</span>
                      &quot;
                    </p>
                    <span className="text-orange-400 font-bold font-mono">
                      — {t.name}
                    </span>
                  </div>
                ))}
              </div>
            </section>

            {/* Project Showcase Section */}
            <section
              id="projects"
              className="projects-section mt-28 w-full flex flex-col items-center px-4 sm:px-8 scroll-mt-20"
            >
              <h2 className="section-title text-4xl font-bold mb-4 text-center font-mono">
                <span className="text-orange-400">Featured</span>
                <span className="text-gray-400">.</span>
                <span className="text-blue-400">Projects</span>
                <span className="text-gray-400">()</span>
              </h2>
              <div className="section-line h-1 w-24 mx-auto mb-12 bg-gray-700"></div>
              <div className="card-container grid gap-8 grid-cols-1 md:grid-cols-3 w-full max-w-6xl">
                {projects.map((proj) => (
                  <div
                    key={proj.title}
                    className={`animated-card card-hover-effect bg-[#252526] border border-gray-700 rounded-lg p-8 flex flex-col text-center relative group`}
                  >
                    <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-green-900/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-lg pointer-events-none"></div>
                    <h3 className="text-xl font-semibold mb-2 font-mono text-orange-400 group-hover:text-green-400 transition-colors">
                      {proj.title}
                    </h3>
                    <p className="text-gray-400 mb-4">{proj.desc}</p>
                    <CodeSnippet codeLines={proj.code} />
                    <div className="flex justify-center mt-6 gap-3">
                      <a
                        href="#"
                        className="inline-block px-6 py-2 bg-green-500 text-black font-mono font-bold rounded hover:bg-green-400 transition-colors code-button-glow"
                      >
                        View Project
                      </a>
                      <a
                        href="#"
                        className="inline-block px-4 py-2 bg-transparent text-green-400 font-mono border border-green-500 rounded hover:bg-green-900/20 transition-colors"
                      >
                        <span className="flex items-center">
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            className="h-4 w-4 mr-1"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                            />
                          </svg>{" "}
                          Code
                        </span>
                      </a>
                    </div>
                    <span className="keyboard-shortcut">
                      Ctrl+{proj.title.charAt(0)}
                    </span>
                  </div>
                ))}
              </div>
            </section>

            {/* Tech Stack Section */}
            <section
              id="tech-stack"
              className="tech-stack-section mt-28 w-full flex flex-col items-center px-4 sm:px-8 scroll-mt-20"
            >
              <h2 className="section-title text-4xl font-bold mb-4 text-center font-mono">
                <span className="text-orange-400">Tech</span>
                <span className="text-gray-400">.</span>
                <span className="text-blue-400">Stack</span>
                <span className="text-gray-400">()</span>
              </h2>
              <div className="section-line h-1 w-24 mx-auto mb-12 bg-gray-700"></div>
              <div
                className="w-full overflow-hidden relative"
                style={{ scrollbarWidth: "none", height: "calc(160px + 2mm)" }}
              >
                <div
                  className="marquee-track flex"
                  style={{ whiteSpace: "nowrap" }}
                >
                  <div className="marquee-track flex">
                    {[...techStack, ...techStack].map((tech, index) => (
                      <div
                        key={`${tech.name}-${index}`}
                        className="scroller-item flex-shrink-0 flex flex-col items-center justify-center p-6 mx-4 bg-[#252526] border border-gray-700 rounded-lg w-40 h-40 card-hover-effect"
                        style={{
                          position: "relative",
                          overflow: "hidden",
                        }}
                      >
                        <div className="tech-icon-container transition-transform duration-300 hover:scale-110">
                          {tech.icon}
                        </div>
                        <p className="mt-4 font-mono text-gray-400 group-hover:text-green-400 transition-colors">
                          {tech.name}
                        </p>
                        <div className="absolute inset-0 bg-gradient-to-b from-green-900/0 to-green-900/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"></div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              <style>{`
                .marquee-track::-webkit-scrollbar { display: none; }
                .tech-stack-card { opacity: 1; transform: none; }
                .marquee-track {
                  display: flex;
                  white-space: nowrap;
                  animation: scroll-right-to-left 40s linear infinite;
                }
                .marquee-track:hover {
                  animation-play-state: paused;
                }
                .scroller-item:first-child { margin-left: 0; }
                .scroller-item:last-child { margin-right: 0; }
                .scroller-item:hover {
                  border-left: 1px solid #39ff14 !important;
                  border-right: 1px solid #39ff14 !important;
                  border-top: none !important;
                  border-bottom: none !important;
                  box-shadow: 0 0 12px rgba(57,255,20,0.4);
                  transform: scale(1.04);
                  transition: border-color 0.2s, border-width 0.2s, transform 0.2s, box-shadow 0.2s;
                  z-index: 1;
                }
                @keyframes scroll-right-to-left {
                  0% { transform: translateX(0); }
                  100% { transform: translateX(-50%); }
                }
              `}</style>
            </section>
            <Footer />
          </div>
        </div>
      </>
    );
  };

  return <Home />;
}

export default App;
