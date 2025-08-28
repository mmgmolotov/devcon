module.exports = {
  darkMode: "class",
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
    "./src/app/**/*.{js,ts,jsx,tsx}",
    "./src/components/**/*.{js,ts,jsx,tsx}",
    "./src/layout/**/*.{js,ts,jsx,tsx}",
    "./src/auth/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        gold: {
          DEFAULT: "#FFD700",
          dark: "#B8860B",
        },
        devdark: {
          DEFAULT: "#18181B",
          light: "#23232A",
        },
        accent: {
          DEFAULT: "#FFD700", // gold accent
        },
      },
      fontFamily: {
        sans: [
          "Inter",
          "Fira Code",
          "JetBrains Mono",
          "ui-sans-serif",
          "system-ui",
        ],
        mono: ["Fira Code", "JetBrains Mono", "ui-monospace", "SFMono-Regular"],
      },
      boxShadow: {
        gold: "0 4px 14px 0 rgba(255, 215, 0, 0.25)",
      },
      borderColor: {
        gold: "#FFD700",
      },
    },
  },
  plugins: [require("@tailwindcss/typography"), require("@tailwindcss/forms")],
};
