import React from "react";
import Link from "next/link";

const Navbar: React.FC = () => {
  return (
    <nav className="bg-gradient-to-r from-devdark via-devdark to-gold sticky top-0 z-50 shadow-gold font-sans border-b-4 border-gold">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          {/* Logo and Brand */}
          <Link href="/" className="flex items-center gap-3 group">
            <span className="flex items-center gap-2 cursor-pointer">
              <svg
                width="36"
                height="36"
                viewBox="0 0 36 36"
                fill="none"
                className="text-gold group-hover:scale-110 transition-transform"
              >
                <rect
                  x="4"
                  y="4"
                  width="28"
                  height="28"
                  rx="8"
                  fill="currentColor"
                  stroke="#FFD700"
                  strokeWidth="2"
                />
                <text
                  x="18"
                  y="24"
                  textAnchor="middle"
                  fontSize="16"
                  fill="#18181B"
                  fontFamily="Fira Code, JetBrains Mono, monospace"
                >
                  {"</>"}
                </text>
              </svg>
              <span className="text-3xl font-extrabold tracking-tight font-mono text-gold group-hover:text-yellow-400 transition-colors drop-shadow-gold">
                DevCON
              </span>
            </span>
          </Link>
          {/* Navigation Links */}
          <div className="hidden md:flex items-center gap-2">
            <Link href="/auth/login">
              <span className="px-5 py-2 rounded-full text-base font-semibold transition bg-devdark text-gold border-2 border-gold hover:bg-gradient-to-r hover:from-gold hover:to-devdark hover:text-devdark focus:outline-none focus:ring-2 focus:ring-gold cursor-pointer font-mono shadow-gold hover:scale-105">
                Login
              </span>
            </Link>
            <Link href="/auth/register">
              <span className="px-5 py-2 rounded-full text-base font-semibold transition bg-gold text-devdark border-2 border-gold hover:bg-gradient-to-r hover:from-devdark hover:to-gold hover:text-gold focus:outline-none focus:ring-2 focus:ring-gold cursor-pointer font-mono shadow-gold hover:scale-105">
                Register
              </span>
            </Link>
          </div>
        </div>
      </div>
      {/* Mobile Nav */}
      <div className="md:hidden flex justify-center gap-2 py-2 bg-gradient-to-r from-devdark via-devdark to-gold border-t-4 border-gold">
        <Link href="/auth/login">
          <span className="px-4 py-2 rounded-full text-base font-semibold transition bg-devdark text-gold border-2 border-gold hover:bg-gradient-to-r hover:from-gold hover:to-devdark hover:text-devdark focus:outline-none focus:ring-2 focus:ring-gold cursor-pointer font-mono shadow-gold hover:scale-105">
            Login
          </span>
        </Link>
        <Link href="/auth/register">
          <span className="px-4 py-2 rounded-full text-base font-semibold transition bg-gold text-devdark border-2 border-gold hover:bg-gradient-to-r hover:from-devdark hover:to-gold hover:text-gold focus:outline-none focus:ring-2 focus:ring-gold cursor-pointer font-mono shadow-gold hover:scale-105">
            Register
          </span>
        </Link>
      </div>
    </nav>
  );
};

export default Navbar;
