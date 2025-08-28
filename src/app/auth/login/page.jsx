"use client";
import React from "react";
import TerminalEmulator from "@/components/terminal/TerminalEmulator";
import supabase from "@/auth/supabase";
import Link from "next/link";

export default function LoginPage() {
  return (
    <div className="min-h-screen bg-[#1e1e1e] flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-4xl">
        <div className="mb-6 flex justify-between items-center">
          <Link
            href="/"
            className="text-green-400 hover:text-green-300 transition-colors"
          >
            <span className="font-mono text-lg">cd ..</span>
          </Link>
          <h1 className="text-3xl font-mono text-center text-green-400 code-text-glow">
            // DevCON <span className="text-gray-400">Login</span>
          </h1>
          <Link
            href="/auth/register"
            className="text-green-400 hover:text-green-300 transition-colors"
          >
            <span className="font-mono text-sm">
              Need an account? ./register
            </span>
          </Link>
        </div>

        <TerminalEmulator
          mode="login"
          onCommand={async (command, args) => {
            if (command === "login") {
              const { email, password } = args;
              const { error } = await supabase.auth.signInWithPassword({
                email,
                password,
              });
              if (error) {
                return {
                  success: false,
                  message: "Login failed. Please check your credentials.",
                };
              }
              return {
                success: true,
                message: "Login successful! Redirecting...",
              };
            }
            return { success: false, message: "Unknown command." };
          }}
        />

        <div className="mt-6 text-center text-gray-500 text-sm">
          <p>
            Hint: Use arrow keys to navigate command history. Press Tab to
            autocomplete commands.
          </p>
          <p className="mt-2">
            <kbd className="px-2 py-1 bg-gray-800 rounded border border-gray-700 text-xs mr-1">
              ↑
            </kbd>
            <kbd className="px-2 py-1 bg-gray-800 rounded border border-gray-700 text-xs mr-1">
              ↓
            </kbd>
            Command history &nbsp;
            <kbd className="px-2 py-1 bg-gray-800 rounded border border-gray-700 text-xs">
              Tab
            </kbd>
            Autocomplete
          </p>
        </div>
      </div>
    </div>
  );
}
