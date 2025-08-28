import React from "react";

const Register: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gold via-devdark to-black font-mono">
      <div className="w-full max-w-md p-8 space-y-8 bg-devdark rounded-2xl shadow-gold border-4 border-gold">
        <h1 className="text-3xl font-extrabold text-center text-gold drop-shadow-gold mb-2">
          Create Your DevCON Account
        </h1>
        <div className="h-1 w-24 mx-auto mb-6 bg-gradient-to-r from-gold via-yellow-400 to-gold rounded-full shadow-gold"></div>
        <form>
          <div className="mb-6">
            <label
              htmlFor="email"
              className="block text-sm font-bold text-gold mb-1"
            >
              Email
            </label>
            <input
              type="email"
              id="email"
              name="email"
              className="block w-full px-4 py-2 border-2 border-gold rounded-lg bg-black text-gold focus:outline-none focus:ring-2 focus:ring-gold font-mono placeholder:text-gold/60 transition-all"
              placeholder="Enter your email"
              required
            />
            <p className="text-xs text-red-500 mt-1 hidden" id="emailError">
              Please enter a valid email address.
            </p>
          </div>
          <div className="mb-6">
            <label
              htmlFor="password"
              className="block text-sm font-bold text-gold mb-1"
            >
              Password
            </label>
            <input
              type="password"
              id="password"
              name="password"
              className="block w-full px-4 py-2 border-2 border-gold rounded-lg bg-black text-gold focus:outline-none focus:ring-2 focus:ring-gold font-mono placeholder:text-gold/60 transition-all"
              placeholder="Enter your password"
              required
            />
            <p className="text-xs text-red-500 mt-1 hidden" id="passwordError">
              Password must be at least 8 characters long.
            </p>
          </div>
          <div className="mb-8">
            <label
              htmlFor="confirmPassword"
              className="block text-sm font-bold text-gold mb-1"
            >
              Confirm Password
            </label>
            <input
              type="password"
              id="confirmPassword"
              name="confirmPassword"
              className="block w-full px-4 py-2 border-2 border-gold rounded-lg bg-black text-gold focus:outline-none focus:ring-2 focus:ring-gold font-mono placeholder:text-gold/60 transition-all"
              placeholder="Confirm your password"
              required
            />
            <p
              className="text-xs text-red-500 mt-1 hidden"
              id="confirmPasswordError"
            >
              Passwords do not match.
            </p>
          </div>
          <button
            type="submit"
            className="w-full px-4 py-2 font-bold text-devdark bg-gradient-to-r from-gold via-yellow-400 to-gold rounded-full shadow-gold border-2 border-gold hover:bg-gold-dark hover:text-gold transition-all focus:outline-none focus:ring-2 focus:ring-gold animate-pop"
            onClick={(e) => {
              e.preventDefault();
              const email = document.getElementById(
                "email",
              ) as HTMLInputElement;
              const password = document.getElementById(
                "password",
              ) as HTMLInputElement;
              const confirmPassword = document.getElementById(
                "confirmPassword",
              ) as HTMLInputElement;
              const emailError = document.getElementById("emailError")!;
              const passwordError = document.getElementById("passwordError")!;
              const confirmPasswordError = document.getElementById(
                "confirmPasswordError",
              )!;

              let valid = true;

              if (!email.value.includes("@")) {
                emailError.classList.remove("hidden");
                valid = false;
              } else {
                emailError.classList.add("hidden");
              }

              if (password.value.length < 8) {
                passwordError.classList.remove("hidden");
                valid = false;
              } else {
                passwordError.classList.add("hidden");
              }

              if (password.value !== confirmPassword.value) {
                confirmPasswordError.classList.remove("hidden");
                valid = false;
              } else {
                confirmPasswordError.classList.add("hidden");
              }

              if (valid) {
                alert("Registration successful!");
              }
            }}
          >
            Register
          </button>
        </form>
        <p className="text-sm text-center text-gold/80 mt-4">
          Already have an account?{" "}
          <a
            href="/auth/login"
            className="text-gold underline hover:text-yellow-400 font-bold"
          >
            Login
          </a>
        </p>
      </div>
    </div>
  );
};

export default Register;
