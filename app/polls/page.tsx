"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { getPolls, Poll } from "@/lib/polls";

export default function PollsPage() {
  const [polls, setPolls] = useState<Poll[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchPolls() {
      try {
        setLoading(true);
        const data = await getPolls();
        setPolls(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to fetch polls");
      } finally {
        setLoading(false);
      }
    }

    fetchPolls();
  }, []);

  const activePolls = polls.filter((poll) => poll.is_active);
  const completedPolls = polls.filter((poll) => !poll.is_active);

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <div className="container mx-auto px-4 py-8">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Community Polls
              </h1>
              <p className="text-gray-600 dark:text-gray-400 mt-2">
                Share your opinions and see what the developer community thinks
              </p>
            </div>
            <Link href="/">
              <Button variant="outline">← Back to Home</Button>
            </Link>
          </div>

          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
        </div>
      </main>
    );
  }

  if (error) {
    return (
      <main className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <div className="container mx-auto px-4 py-8">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Community Polls
              </h1>
              <p className="text-gray-600 dark:text-gray-400 mt-2">
                Share your opinions and see what the developer community thinks
              </p>
            </div>
            <Link href="/">
              <Button variant="outline">← Back to Home</Button>
            </Link>
          </div>

          <div className="flex flex-col items-center justify-center h-64">
            <div className="text-red-500 mb-4">⚠️</div>
            <p className="text-red-600 dark:text-red-400 text-center">
              {error}
            </p>
            <Button
              onClick={() => window.location.reload()}
              className="mt-4"
              variant="outline"
            >
              Try Again
            </Button>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
              Community Polls
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Share your opinions and see what the developer community thinks
            </p>
          </div>
          <Link href="/">
            <Button variant="outline">← Back to Home</Button>
          </Link>
        </div>

        {/* Active Polls */}
        {activePolls.length > 0 && (
          <section className="mb-12">
            <div className="flex items-center gap-2 mb-6">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white">
                Active Polls
              </h2>
              <Badge
                variant="secondary"
                className="bg-green-100 text-green-800"
              >
                {activePolls.length} active
              </Badge>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
              {activePolls.map((poll) => (
                <div
                  key={poll.id}
                  className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-200 dark:border-gray-700 hover:shadow-md transition-shadow duration-200"
                >
                  <div className="flex items-start justify-between mb-4">
                    <Badge variant="outline" className="text-xs">
                      {poll.category}
                    </Badge>
                    <div className="flex items-center gap-1 text-sm text-gray-500 dark:text-gray-400">
                      <span>👥</span>
                      <span>{poll.total_votes}</span>
                    </div>
                  </div>

                  <h3 className="font-semibold text-gray-900 dark:text-white mb-2 leading-snug">
                    {poll.title}
                  </h3>

                  <p className="text-gray-600 dark:text-gray-300 text-sm mb-4 line-clamp-2">
                    {poll.description}
                  </p>

                  <div className="text-xs text-gray-500 dark:text-gray-400 mb-4">
                    {poll.total_options} options available
                  </div>

                  <Link href={`/polls/${poll.id}`} className="block">
                    <Button className="w-full bg-blue-600 hover:bg-blue-700 text-white">
                      Vote Now
                    </Button>
                  </Link>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Completed Polls */}
        {completedPolls.length > 0 && (
          <section>
            <div className="flex items-center gap-2 mb-6">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white">
                Completed Polls
              </h2>
              <Badge variant="secondary" className="bg-gray-100 text-gray-600">
                {completedPolls.length} completed
              </Badge>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
              {completedPolls.map((poll) => (
                <div
                  key={poll.id}
                  className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-200 dark:border-gray-700 opacity-75"
                >
                  <div className="flex items-start justify-between mb-4">
                    <Badge variant="outline" className="text-xs opacity-60">
                      {poll.category}
                    </Badge>
                    <div className="flex items-center gap-1 text-sm text-gray-500 dark:text-gray-400">
                      <span>👥</span>
                      <span>{poll.total_votes}</span>
                    </div>
                  </div>

                  <h3 className="font-semibold text-gray-900 dark:text-white mb-2 leading-snug">
                    {poll.title}
                  </h3>

                  <p className="text-gray-600 dark:text-gray-300 text-sm mb-4 line-clamp-2">
                    {poll.description}
                  </p>

                  <Link href={`/polls/${poll.id}`} className="block">
                    <Button variant="outline" className="w-full" disabled>
                      View Results
                    </Button>
                  </Link>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Empty state */}
        {polls.length === 0 && (
          <div className="flex flex-col items-center justify-center h-64">
            <div className="text-4xl mb-4">🗳️</div>
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              No polls available
            </h3>
            <p className="text-gray-600 dark:text-gray-400 text-center">
              Check back later for new polls from the community
            </p>
          </div>
        )}
      </div>
    </main>
  );
}
