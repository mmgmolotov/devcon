"use client";
import React, { useState, useEffect } from "react";
import Link from "next/link";

export default function DashboardPage() {
  const [username, setUsername] = useState("developer");
  const [lastLogin, setLastLogin] = useState("N/A");
  const [projects, setProjects] = useState([]);
  const [activities, setActivities] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Simulate loading data
    const timer = setTimeout(() => {
      setUsername("dev_enthusiast");
      setLastLogin(new Date().toLocaleString());

      setProjects([
        { id: 1, name: "Open Source Chat App", language: "JavaScript", stars: 24, lastUpdated: "2 hours ago" },
        { id: 2, name: "API Playground", language: "TypeScript", stars: 17, lastUpdated: "1 day ago" },
        { id: 3, name: "Portfolio Builder", language: "React", stars: 45, lastUpdated: "3 days ago" }
      ]);

      setActivities([
        { id: 1, type: "commit", project: "API Playground", message: "Fix authentication bug", time: "1 hour ago" },
        { id: 2, type: "issue", project: "Open Source Chat App", message: "New feature request: Dark mode", time: "5 hours ago" },
        { id: 3, type: "pull", project: "Portfolio Builder", message: "Add responsive design", time: "1 day ago" },
        { id: 4, type: "star", project: "API Playground", message: "Received a new star!", time: "2 days ago" }
      ]);

      setIsLoading(false);
    }, 1500);

    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="min-h-screen bg-[#1e1e1e] text-gray-300">
      {/* Terminal-style header */}
      <header className="bg-black border-b border-green-700 text-green-400 py-2 px-4 font-mono flex justify-between items-center">
        <div className="flex items-center">
          <span className="text-green-500 mr-2">$</span>
          <span className="text-white">devcon</span>
          <span className="text-yellow-500 ml-2">dashboard</span>
          <span className="blink ml-2">|</span>
        </div>
        <div className="flex items-center space-x-4">
          <Link href="/" className="text-gray-400 hover:text-green-400 transition-colors">
            Home
          </Link>
          <div className="relative group">
            <button className="text-gray-400 hover:text-green-400 transition-colors flex items-center">
              {username}
              <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>
            <div className="absolute right-0 mt-2 w-48 bg-gray-900 border border-green-700 rounded shadow-lg py-1 z-10 hidden group-hover:block">
              <a href="#" className="block px-4 py-2 text-sm hover:bg-gray-800">Profile</a>
              <a href="#" className="block px-4 py-2 text-sm hover:bg-gray-800">Settings</a>
              <a href="/" className="block px-4 py-2 text-sm hover:bg-gray-800 text-red-400">Logout</a>
            </div>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="container mx-auto px-4 py-8">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center h-64">
            <div className="terminal-loader mb-4"></div>
            <p className="text-gray-500 font-mono">Loading dashboard data...</p>
          </div>
        ) : (
          <>
            {/* Welcome banner */}
            <div className="bg-gradient-to-r from-gray-900 to-gray-800 rounded-lg p-6 mb-8 border border-gray-700">
              <div className="flex flex-col md:flex-row justify-between">
                <div>
                  <h1 className="text-2xl font-bold mb-2">Welcome back, <span className="text-green-400">{username}</span></h1>
                  <p className="text-gray-400">Last login: {lastLogin}</p>
                </div>
                <div className="mt-4 md:mt-0">
                  <button className="bg-green-500 text-black px-4 py-2 rounded font-mono hover:bg-green-400 transition-colors">
                    + New Project
                  </button>
                </div>
              </div>
            </div>

            {/* Dashboard grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              {/* Projects section */}
              <div className="lg:col-span-2">
                <div className="bg-[#252526] rounded-lg border border-gray-700 overflow-hidden">
                  <div className="flex justify-between items-center p-4 border-b border-gray-700">
                    <h2 className="text-xl font-mono text-green-400">
                      <span className="text-gray-400">$</span> ls ./projects
                    </h2>
                    <button className="text-sm text-gray-400 hover:text-green-400">View All</button>
                  </div>
                  <div className="divide-y divide-gray-700">
                    {projects.map(project => (
                      <div key={project.id} className="p-4 hover:bg-gray-800 transition-colors">
                        <div className="flex justify-between">
                          <div className="flex items-center">
                            <div className="w-3 h-3 rounded-full bg-green-500 mr-3"></div>
                            <h3 className="font-medium">{project.name}</h3>
                          </div>
                          <div className="text-sm text-gray-500">{project.lastUpdated}</div>
                        </div>
                        <div className="mt-2 flex justify-between">
                          <span className="text-sm text-gray-400">{project.language}</span>
                          <div className="flex items-center text-sm text-yellow-400">
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                            </svg>
                            {project.stars}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Activity feed */}
              <div className="lg:col-span-1">
                <div className="bg-[#252526] rounded-lg border border-gray-700 overflow-hidden h-full">
                  <div className="p-4 border-b border-gray-700">
                    <h2 className="text-xl font-mono text-green-400">
                      <span className="text-gray-400">$</span> tail -f ./activity.log
                    </h2>
                  </div>
                  <div className="p-4 overflow-y-auto" style={{ maxHeight: "400px" }}>
                    {activities.map(activity => (
                      <div key={activity.id} className="mb-4 last:mb-0">
                        <div className="flex items-start">
                          <div className="mr-3 mt-1">
                            {activity.type === "commit" && (
                              <div className="w-4 h-4 bg-green-500 rounded-full"></div>
                            )}
                            {activity.type === "issue" && (
                              <div className="w-4 h-4 bg-purple-500 rounded-full"></div>
                            )}
                            {activity.type === "pull" && (
                              <div className="w-4 h-4 bg-blue-500 rounded-full"></div>
                            )}
                            {activity.type === "star" && (
                              <div className="w-4 h-4 bg-yellow-500 rounded-full"></div>
                            )}
                          </div>
                          <div>
                            <div className="font-medium">{activity.message}</div>
                            <div className="text-sm text-gray-500">
                              {activity.project} • {activity.time}
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Quick actions */}
            <div className="mt-8 grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="bg-[#252526] p-4 rounded-lg border border-gray-700 hover:border-green-500 transition-colors cursor-pointer group">
                <div className="flex items-center">
                  <div className="w-10 h-10 bg-green-500/20 rounded-lg flex items-center justify-center text-green-400 mr-3 group-hover:bg-green-500 group-hover:text-black transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="font-medium">New Project</h3>
                    <p className="text-sm text-gray-500">Start coding</p>
                  </div>
                </div>
              </div>
              <div className="bg-[#252526] p-4 rounded-lg border border-gray-700 hover:border-blue-500 transition-colors cursor-pointer group">
                <div className="flex items-center">
                  <div className="w-10 h-10 bg-blue-500/20 rounded-lg flex items-center justify-center text-blue-400 mr-3 group-hover:bg-blue-500 group-hover:text-black transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="font-medium">Find Team</h3>
                    <p className="text-sm text-gray-500">Collaborate</p>
                  </div>
                </div>
              </div>
              <div className="bg-[#252526] p-4 rounded-lg border border-gray-700 hover:border-purple-500 transition-colors cursor-pointer group">
                <div className="flex items-center">
                  <div className="w-10 h-10 bg-purple-500/20 rounded-lg flex items-center justify-center text-purple-400 mr-3 group-hover:bg-purple-500 group-hover:text-black transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="font-medium">Challenges</h3>
                    <p className="text-sm text-gray-500">Test your skills</p>
                  </div>
                </div>
              </div>
              <div className="bg-[#252526] p-4 rounded-lg border border-gray-700 hover:border-orange-500 transition-colors cursor-pointer group">
                <div className="flex items-center">
                  <div className="w-10 h-10 bg-orange-500/20 rounded-lg flex items-center justify-center text-orange-400 mr-3 group-hover:bg-orange-500 group-hover:text-black transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="font-medium">Resources</h3>
                    <p className="text-sm text-gray-500">Learning tools</p>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}
      </main>

      <style jsx>{`
        .terminal-loader {
          border: 3px solid rgba(57, 255, 20, 0.3);
          border-radius: 50%;
          border-top: 3px solid rgba(57, 255, 20, 1);
          width: 40px;
          height: 40px;
          animation: spin 1s linear infinite;
        }

        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }

        .blink {
          animation: blink-animation 1s steps(2, start) infinite;
        }

        @keyframes blink-animation {
          to { visibility: hidden; }
        }
      `}</style>
    </div>
  );
}
