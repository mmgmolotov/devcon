import React from "react";

const Login: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gold via-devdark to-black font-mono">
      <div className="w-full max-w-md p-8 space-y-8 bg-devdark rounded-2xl shadow-gold border-4 border-gold">
        <h1 className="text-3xl font-extrabold text-center text-gold drop-shadow-gold mb-2 font-mono">
          Login to DevCON
        </h1>
        <div className="h-1 w-24 mx-auto mb-8 bg-gradient-to-r from-gold via-yellow-400 to-gold rounded-full shadow-gold animate-grow"></div>
        <form
          className="space-y-6"
          onSubmit={(e) => {
            e.preventDefault();
            const form = e.target as HTMLFormElement;
            const email = (form.elements.namedItem("email") as HTMLInputElement)
              .value;
            const password = (
              form.elements.namedItem("password") as HTMLInputElement
            ).value;
            if (!email || !password) {
              alert("Please fill in all fields.");
              return;
            }
            // TODO: Add authentication logic here
            alert("Logged in!");
          }}
        >
          <div>
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
              className="w-full px-4 py-2 border-2 border-gold rounded-lg bg-black text-gold focus:outline-none focus:ring-2 focus:ring-gold font-mono placeholder:text-gold/60 transition-shadow shadow-gold"
              placeholder="Enter your email"
              required
            />
          </div>
          <div>
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
              className="w-full px-4 py-2 border-2 border-gold rounded-lg bg-black text-gold focus:outline-none focus:ring-2 focus:ring-gold font-mono placeholder:text-gold/60 transition-shadow shadow-gold"
              placeholder="Enter your password"
              required
            />
          </div>
          <button
            type="submit"
            className="w-full px-4 py-2 mt-6 font-bold text-devdark bg-gradient-to-r from-gold via-yellow-400 to-gold rounded-full shadow-gold border-2 border-gold hover:bg-gold-dark hover:text-gold transition-all focus:outline-none focus:ring-2 focus:ring-gold animate-pop"
          >
            Login
          </button>
        </form>
        <p className="text-sm text-center text-gold/80 mt-4 font-mono">
          Don&apos;t have an account?{" "}
          <a
            href="/auth/register"
            className="text-gold underline hover:text-yellow-400 font-bold transition"
          >
            Register
          </a>
        </p>
      </div>
    </div>
  );
};

export default Login;
