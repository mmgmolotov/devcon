"use client";
import { useEffect, useState } from "react";
import App from "../App";
import Link from "next/link";

export default function Page() {
  const [showTerminalTip, setShowTerminalTip] = useState(false);

  useEffect(() => {
    // Show terminal tip after 5 seconds
    const timer = setTimeout(() => {
      setShowTerminalTip(true);
    }, 5000);

    return () => clearTimeout(timer);
  }, []);

  return (
    <>
      <div className="pb-24">
        <App />
      </div>
      {showTerminalTip && (
        <div className="fixed bottom-8 right-8 bg-black/90 border border-green-500 p-4 rounded-lg shadow-lg z-50 max-w-xs animate-fade-in">
          <div className="flex justify-between items-start mb-2">
            <h3 className="text-green-400 font-mono text-sm">Pro Tip:</h3>
            <button
              onClick={() => setShowTerminalTip(false)}
              className="text-gray-500 hover:text-white"
            >
              ×
            </button>
          </div>
          <p className="text-gray-300 text-sm mb-3">
            Try our new terminal-style login experience for developers!
          </p>
          <div className="flex gap-2">
            <Link
              href="/auth/login"
              className="text-xs bg-green-500 text-black px-3 py-1 rounded font-mono hover:bg-green-400"
            >
              ./login
            </Link>
            <Link
              href="/auth/register"
              className="text-xs bg-transparent text-green-400 border border-green-500 px-3 py-1 rounded font-mono hover:bg-green-900/20"
            >
              ./register
            </Link>
          </div>
        </div>
      )}
      <style jsx>{`
        @keyframes fade-in {
          from {
            opacity: 0;
            transform: translateY(10px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        .animate-fade-in {
          animation: fade-in 0.5s ease forwards;
        }
      `}</style>
    </>
  );
}
