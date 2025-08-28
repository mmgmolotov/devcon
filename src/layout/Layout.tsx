"use client";

import React from "react";
import Link from "next/link";

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const [darkMode, setDarkMode] = React.useState(false);

  const toggleDarkMode = () => {
    setDarkMode(!darkMode);
    if (darkMode) {
      document.documentElement.classList.remove("dark");
    } else {
      document.documentElement.classList.add("dark");
    }
  };

  return (
    <div className={`min-h-screen flex flex-col ${darkMode ? "dark" : ""}`}>
      <header className="bg-gradient-to-r from-gold via-devdark to-gold text-gold py-4 border-b-2 border-gold shadow-gold">
        <div className="container mx-auto flex justify-between items-center px-4">
          <h1 className="text-xl font-bold text-gold drop-shadow-gold">
            <Link href="/">DevCON</Link>
          </h1>
          <nav>
            <ul className="flex space-x-4">
              <li>
                <Link
                  href="/auth/login"
                  className="px-4 py-2 rounded-full bg-gold text-devdark font-bold border-2 border-gold shadow-gold hover:bg-devdark hover:text-gold transition"
                >
                  Login
                </Link>
              </li>
              <li>
                <Link
                  href="/auth/register"
                  className="px-4 py-2 rounded-full bg-devdark text-gold font-bold border-2 border-gold shadow-gold hover:bg-gold hover:text-devdark transition"
                >
                  Register
                </Link>
              </li>
            </ul>
          </nav>
          <button
            onClick={toggleDarkMode}
            className="ml-4 px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600"
          >
            {darkMode ? "Light Mode" : "Dark Mode"}
          </button>
        </div>
      </header>
      <main className="flex-grow container mx-auto px-4 py-8">{children}</main>
      <footer className="bg-gray-800 text-white py-4">
        <div className="container mx-auto text-center">
          <p>&copy; {new Date().getFullYear()} DevCON. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default Layout;
