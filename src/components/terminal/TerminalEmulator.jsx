import React, { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";

// ASCII Art for the logo
const ASCII_LOGO = `
██████╗ ███████╗██╗   ██╗ ██████╗ ██████╗ ███╗   ██╗
██╔══██╗██╔════╝██║   ██║██╔════╝██╔═══██╗████╗  ██║
██║  ██║█████╗  ██║   ██║██║     ██║   ██║██╔██╗ ██║
██║  ██║██╔══╝  ╚██╗ ██╔╝██║     ██║   ██║██║╚██╗██║
██████╔╝███████╗ ╚████╔╝ ╚██████╗╚██████╔╝██║ ╚████║
╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝
`;

const WELCOME_MESSAGE = "Welcome to DevCON Terminal v1.0.0";
const HELP_TEXT = `
Available commands:
  login           - Access your account
  register        - Create a new account
  help            - Show this message
  clear           - Clear the terminal
  exit            - Return to main page
`;

export default function TerminalEmulator({ mode = "login" }) {
  const router = useRouter();
  const [lines, setLines] = useState([]);
  const [inputValue, setInputValue] = useState("");
  const [currentMode, setCurrentMode] = useState(mode);
  const [currentPrompt, setCurrentPrompt] = useState("guest@devcon:~$ ");
  const [commandHistory, setCommandHistory] = useState([]);
  const [historyIndex, setHistoryIndex] = useState(-1);
  const [credentials, setCredentials] = useState({
    username: "",
    email: "",
    password: "",
  });
  const [loginStep, setLoginStep] = useState(0);
  const [registerStep, setRegisterStep] = useState(0);
  const [loading, setLoading] = useState(false);

  const terminalEndRef = useRef(null);
  const inputRef = useRef(null);

  // Initialize the terminal
  useEffect(() => {
    const initialLines = [
      { type: "ascii", content: ASCII_LOGO },
      { type: "system", content: WELCOME_MESSAGE },
      { type: "system", content: `Type 'help' for available commands` },
      { type: "blank", content: "" },
    ];

    // Show login or register prompts based on initial mode
    if (currentMode === "login") {
      initialLines.push({ type: "system", content: "Starting login sequence..." });
      initialLines.push({ type: "prompt", content: "Enter username:" });
    } else if (currentMode === "register") {
      initialLines.push({ type: "system", content: "Starting registration sequence..." });
      initialLines.push({ type: "prompt", content: "Enter username:" });
    }

    setLines(initialLines);

    // Auto focus the input field
    if (inputRef.current) {
      inputRef.current.focus();
    }
  }, []);

  // Scroll to bottom when lines change
  useEffect(() => {
    if (terminalEndRef.current) {
      terminalEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [lines]);

  // Keep input focused
  useEffect(() => {
    function handleClick() {
      if (inputRef.current) {
        inputRef.current.focus();
      }
    }
    document.addEventListener("click", handleClick);
    return () => {
      document.removeEventListener("click", handleClick);
    };
  }, []);

  const addLine = (content, type = "command") => {
    setLines((prev) => [...prev, { type, content }]);
  };

  const handleSubmit = (e) => {
    e.preventDefault();

    if (inputValue.trim() === "") return;

    // Add the current command to display
    addLine(`${currentPrompt}${inputValue}`, "user");

    // Handle login/register flow
    if (currentMode === "login" && loginStep > 0) {
      handleLoginFlow();
    } else if (currentMode === "register" && registerStep > 0) {
      handleRegisterFlow();
    } else {
      // Process commands
      processCommand(inputValue.trim().toLowerCase());
    }

    // Add to command history
    if (inputValue.trim()) {
      setCommandHistory((prev) => [inputValue, ...prev]);
      setHistoryIndex(-1);
    }

    setInputValue("");
  };

  const processCommand = (cmd) => {
    switch (cmd) {
      case "help":
        addLine(HELP_TEXT, "system");
        break;

      case "clear":
        setLines([]);
        break;

      case "exit":
        addLine("Logging out... Redirecting to main page.", "system");
        setTimeout(() => router.push("/"), 1500);
        break;

      case "login":
        if (currentMode === "login") {
          addLine("Login process already started.", "error");
        } else {
          setCurrentMode("login");
          setLoginStep(1);
          addLine("Starting login sequence...", "system");
          addLine("Enter username:", "prompt");
        }
        break;

      case "register":
        if (currentMode === "register") {
          addLine("Registration process already started.", "error");
        } else {
          setCurrentMode("register");
          setRegisterStep(1);
          addLine("Starting registration sequence...", "system");
          addLine("Enter username:", "prompt");
        }
        break;

      default:
        addLine(`Command not found: ${cmd}. Type 'help' for available commands.`, "error");
    }
  };

  const handleLoginFlow = () => {
    switch (loginStep) {
      case 1:
        setCredentials({ ...credentials, username: inputValue });
        setLoginStep(2);
        addLine("Enter password:", "prompt");
        break;

      case 2:
        setCredentials({ ...credentials, password: inputValue });
        setLoginStep(3);
        simulateLogin();
        break;
    }
  };

  const handleRegisterFlow = () => {
    switch (registerStep) {
      case 1:
        setCredentials({ ...credentials, username: inputValue });
        setRegisterStep(2);
        addLine("Enter email:", "prompt");
        break;

      case 2:
        setCredentials({ ...credentials, email: inputValue });
        setRegisterStep(3);
        addLine("Enter password:", "prompt");
        break;

      case 3:
        setCredentials({ ...credentials, password: inputValue });
        setRegisterStep(4);
        simulateRegistration();
        break;
    }
  };

  const simulateLogin = () => {
    setLoading(true);
    addLine("Authenticating...", "system");

    setTimeout(() => {
      setLoading(false);
      // In a real app, you would verify credentials here
      const success = true; // Simulate successful login

      if (success) {
        addLine("Login successful! Welcome back.", "success");
        setCurrentPrompt(`${credentials.username}@devcon:~$ `);
        setCurrentMode("command");
        setLoginStep(0);

        // Redirect to dashboard or home page
        addLine("Redirecting to dashboard...", "system");
        setTimeout(() => router.push("/dashboard"), 1500);
      } else {
        addLine("Login failed. Invalid username or password.", "error");
        setLoginStep(1);
        addLine("Enter username:", "prompt");
      }
    }, 2000);
  };

  const simulateRegistration = () => {
    setLoading(true);
    addLine("Creating account...", "system");

    setTimeout(() => {
      setLoading(false);
      // In a real app, you would create an account here
      const success = true; // Simulate successful registration

      if (success) {
        addLine("Registration successful! Account created.", "success");
        setCurrentPrompt(`${credentials.username}@devcon:~$ `);
        setCurrentMode("command");
        setRegisterStep(0);

        // Auto-login after registration
        addLine("Logging in automatically...", "system");
        addLine("Redirecting to dashboard...", "system");
        setTimeout(() => router.push("/dashboard"), 1500);
      } else {
        addLine("Registration failed. Username or email already exists.", "error");
        setRegisterStep(1);
        addLine("Enter username:", "prompt");
      }
    }, 2000);
  };

  // Handle arrow keys for command history
  const handleKeyDown = (e) => {
    if (e.key === "ArrowUp") {
      e.preventDefault();

      const nextIndex = Math.min(historyIndex + 1, commandHistory.length - 1);
      setHistoryIndex(nextIndex);

      if (commandHistory[nextIndex]) {
        setInputValue(commandHistory[nextIndex]);
      }
    } else if (e.key === "ArrowDown") {
      e.preventDefault();

      if (historyIndex <= 0) {
        setHistoryIndex(-1);
        setInputValue("");
        return;
      }

      const nextIndex = historyIndex - 1;
      setHistoryIndex(nextIndex);

      if (commandHistory[nextIndex]) {
        setInputValue(commandHistory[nextIndex]);
      }
    } else if (e.key === "Tab") {
      e.preventDefault();
      // Simple auto-complete for commands
      const commands = ["login", "register", "help", "clear", "exit"];
      const inputLower = inputValue.toLowerCase();

      if (inputLower) {
        const matchedCommand = commands.find(cmd => cmd.startsWith(inputLower));
        if (matchedCommand) {
          setInputValue(matchedCommand);
        }
      }
    }
  };

  return (
    <div className="w-full h-full bg-black text-green-400 font-mono p-4 rounded-md border border-green-700 overflow-hidden flex flex-col terminal-container">
      <div className="terminal-header flex items-center justify-between mb-2 pb-2 border-b border-green-700">
        <div className="flex space-x-2">
          <div className="w-3 h-3 rounded-full bg-red-500"></div>
          <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
          <div className="w-3 h-3 rounded-full bg-green-500"></div>
        </div>
        <div className="text-xs opacity-80">devcon-terminal@{currentMode}.sh</div>
        <div className="text-xs opacity-80">v1.0.0</div>
      </div>

      <div className="terminal-output flex-grow overflow-y-auto scrollbar-thin scrollbar-thumb-green-700 scrollbar-track-black">
        {lines.map((line, i) => (
          <div key={i} className={`terminal-line ${line.type === 'blank' ? 'h-4' : 'mb-1'}`}>
            {line.type === "ascii" ? (
              <pre className="text-green-500 text-xs sm:text-sm whitespace-pre">{line.content}</pre>
            ) : line.type === "user" ? (
              <div className="text-white">{line.content}</div>
            ) : line.type === "system" ? (
              <div className="text-blue-400">{line.content}</div>
            ) : line.type === "error" ? (
              <div className="text-red-400">{line.content}</div>
            ) : line.type === "success" ? (
              <div className="text-green-500">{line.content}</div>
            ) : line.type === "prompt" ? (
              <div className="text-yellow-400">{line.content}</div>
            ) : (
              <div>{line.content}</div>
            )}
          </div>
        ))}
        <div ref={terminalEndRef} />
      </div>

      <form onSubmit={handleSubmit} className="terminal-input-container mt-2 flex items-center">
        <span className="text-green-400 mr-2">{currentPrompt}</span>
        <input
          ref={inputRef}
          type={
            (currentMode === "login" && loginStep === 2) ||
            (currentMode === "register" && registerStep === 3)
              ? "password"
              : "text"
          }
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={handleKeyDown}
          className="flex-grow bg-transparent border-none outline-none text-green-400 caret-green-400"
          disabled={loading}
          autoComplete="off"
          autoFocus
        />
        {loading && (
          <span className="loading-indicator ml-2">
            <span className="animate-pulse">▋</span>
          </span>
        )}
      </form>

      <style jsx>{`
        .terminal-container {
          height: 70vh;
          box-shadow: 0 0 20px rgba(57, 255, 20, 0.3);
          background-color: rgba(0, 0, 0, 0.9);
        }
        .terminal-output::-webkit-scrollbar {
          width: 5px;
        }
        .terminal-output::-webkit-scrollbar-track {
          background: #111;
        }
        .terminal-output::-webkit-scrollbar-thumb {
          background: #39ff14;
        }
        .loading-indicator {
          animation: blink 1s step-end infinite;
        }
        @keyframes blink {
          from, to { opacity: 1; }
          50% { opacity: 0; }
        }
      `}</style>
    </div>
  );
}
