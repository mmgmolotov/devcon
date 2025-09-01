"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Label } from "@/components/ui/label";
import { Loader2 } from "lucide-react";
import {
  getPollById,
  submitVote,
  hasUserVoted,
  subscribeToPollResults,
  PollDetail,
} from "@/lib/polls";

export default function PollDetailPage({ params }: { params: { id: string } }) {
  const [poll, setPoll] = useState<PollDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedOption, setSelectedOption] = useState<string>("");
  const [hasVoted, setHasVoted] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [voteError, setVoteError] = useState<string | null>(null);

  // Optimistic UI state
  const [optimisticVotes, setOptimisticVotes] = useState<
    Record<string, number>
  >({});

  useEffect(() => {
    async function fetchPollData() {
      try {
        setLoading(true);
        const [pollData, userVoted] = await Promise.all([
          getPollById(params.id),
          hasUserVoted(params.id),
        ]);

        if (!pollData) {
          setError("Poll not found");
          return;
        }

        setPoll(pollData);
        setHasVoted(userVoted);

        // Initialize optimistic votes with current counts
        const initialVotes: Record<string, number> = {};
        pollData.options.forEach((option) => {
          initialVotes[option.id] = option.vote_count;
        });
        setOptimisticVotes(initialVotes);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to fetch poll");
      } finally {
        setLoading(false);
      }
    }

    fetchPollData();
  }, [params.id]);

  // Subscribe to real-time updates
  useEffect(() => {
    if (!poll) return;

    const subscription = subscribeToPollResults(poll.id, (payload) => {
      // Real-time update received, refresh the poll data
      getPollById(poll.id).then((updatedPoll) => {
        if (updatedPoll) {
          setPoll(updatedPoll);
          // Update optimistic votes with real data
          const realVotes: Record<string, number> = {};
          updatedPoll.options.forEach((option) => {
            realVotes[option.id] = option.vote_count;
          });
          setOptimisticVotes(realVotes);
        }
      });
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [poll?.id]);

  const handleVote = async (e: React.FormEvent) => {
    e.preventDefault();
    // #validate-vote
    // AI: Ensure users cannot submit without selecting an option and display inline error messages.
    if (!selectedOption || !poll) return;

    setIsSubmitting(true);
    setVoteError(null);

    // Optimistic UI: immediately show the vote
    setOptimisticVotes((prev) => ({
      ...prev,
      [selectedOption]: (prev[selectedOption] || 0) + 1,
    }));
    setHasVoted(true);

    try {
      // Submit vote to Supabase
      await submitVote(poll.id, selectedOption);

      // Fetch fresh data to ensure accuracy
      const updatedPoll = await getPollById(poll.id);
      if (updatedPoll) {
        setPoll(updatedPoll);
        const realVotes: Record<string, number> = {};
        updatedPoll.options.forEach((option) => {
          realVotes[option.id] = option.vote_count;
        });
        setOptimisticVotes(realVotes);
      }
    } catch (err) {
      // Revert optimistic update on error
      setOptimisticVotes((prev) => ({
        ...prev,
        [selectedOption]: Math.max((prev[selectedOption] || 1) - 1, 0),
      }));
      setHasVoted(false);
      setVoteError(
        err instanceof Error ? err.message : "Failed to submit vote",
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const getPercentage = (optionId: string) => {
    const votes = optimisticVotes[optionId] || 0;
    const total = Object.values(optimisticVotes).reduce(
      (sum, count) => sum + count,
      0,
    );
    return total > 0 ? Math.round((votes / total) * 100) : 0;
  };

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <div className="container mx-auto px-4 py-8">
          <div className="mb-8">
            <Link href="/polls">
              <Button variant="outline" className="mb-4">
                ← Back to Polls
              </Button>
            </Link>
          </div>
          <div className="max-w-2xl mx-auto">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
              <div className="animate-pulse space-y-4">
                <div className="h-4 bg-gray-200 rounded w-1/4"></div>
                <div className="h-8 bg-gray-200 rounded w-3/4"></div>
                <div className="h-4 bg-gray-200 rounded w-full"></div>
                <div className="h-4 bg-gray-200 rounded w-5/6"></div>
              </div>
            </div>
          </div>
        </div>
      </main>
    );
  }

  if (error || !poll) {
    return (
      <main className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <div className="container mx-auto px-4 py-8">
          <div className="mb-8">
            <Link href="/polls">
              <Button variant="outline" className="mb-4">
                ← Back to Polls
              </Button>
            </Link>
          </div>
          <div className="max-w-2xl mx-auto">
            <div className="flex flex-col items-center justify-center h-64">
              <div className="text-red-500 mb-4">⚠️</div>
              <p className="text-red-600 dark:text-red-400 text-center mb-4">
                {error || "Poll not found"}
              </p>
              <Button
                onClick={() => window.location.reload()}
                variant="outline"
              >
                Try Again
              </Button>
            </div>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="container mx-auto px-4 py-8">
        {/* Navigation */}
        <div className="mb-8">
          <Link href="/polls">
            <Button variant="outline" className="mb-4">
              ← Back to Polls
            </Button>
          </Link>
        </div>

        {/* Poll Content */}
        <div className="max-w-2xl mx-auto">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
            {/* Header */}
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <div className="flex items-start justify-between mb-4">
                <Badge variant="outline" className="mb-2">
                  {poll.category}
                </Badge>
                <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                  <span>👥</span>
                  <span>
                    {Object.values(optimisticVotes).reduce(
                      (sum, count) => sum + count,
                      0,
                    )}{" "}
                    votes
                  </span>
                </div>
              </div>

              <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-3">
                {poll.title}
              </h1>

              <p className="text-gray-600 dark:text-gray-300 leading-relaxed">
                {poll.description}
              </p>
            </div>

            {/* Voting Section */}
            {/* @enhance-vote-ui */}
            {/* AI: Improve styling of the voting section, spacing, and buttons using shadcn/ui and Tailwind. Add hover effects, better alignment, and accessibility improvements. */}
            <div className="p-6">
              {!hasVoted ? (
                <form onSubmit={handleVote} className="space-y-6">
                  <div className="space-y-4">
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-4">
                      Choose your answer:
                    </h3>

                    {voteError && (
                      <div className="p-4 bg-red-50 border-l-4 border-red-500 text-red-900 dark:bg-red-900/20 dark:text-red-200 dark:border-red-600 rounded-r-lg">
                        <p className="font-bold">Error Submitting Vote</p>
                        <p className="text-sm">{voteError}</p>
                      </div>
                    )}

                    <RadioGroup
                      value={selectedOption}
                      onValueChange={setSelectedOption}
                      className="space-y-3"
                    >
                      {poll.options.map((option) => (
                        <div
                          key={option.id}
                          className="flex items-center space-x-3 p-4 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                        >
                          <RadioGroupItem
                            value={option.id}
                            id={option.id}
                            className="text-blue-600"
                          />
                          <Label
                            htmlFor={option.id}
                            className="flex-1 text-gray-900 dark:text-white cursor-pointer font-medium"
                          >
                            {option.label}
                          </Label>
                        </div>
                      ))}
                    </RadioGroup>
                  </div>

                  <Button
                    type="submit"
                    disabled={!selectedOption || isSubmitting}
                    className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 flex items-center justify-center"
                  >
                    {isSubmitting ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        <span>Submitting...</span>
                      </>
                    ) : (
                      "Submit Vote"
                    )}
                  </Button>
                </form>
              ) : (
                <div className="space-y-6">
                  {/* Thank you message */}
                  <div className="text-center py-6">
                    <div className="text-6xl mb-4">✅</div>
                    <h3 className="text-xl font-semibold text-green-700 dark:text-green-400 mb-2">
                      Thank you for voting!
                    </h3>
                    <p className="text-gray-600 dark:text-gray-300">
                      Your vote has been recorded. Here are the current results:
                    </p>
                  </div>

                  {/* Results */}
                  <div className="space-y-4">
                    <h4 className="text-lg font-medium text-gray-900 dark:text-white">
                      Current Results
                    </h4>

                    {poll.options
                      .sort(
                        (a, b) =>
                          (optimisticVotes[b.id] || 0) -
                          (optimisticVotes[a.id] || 0),
                      )
                      .map((option) => {
                        const votes = optimisticVotes[option.id] || 0;
                        const percentage = getPercentage(option.id);
                        const isSelected = selectedOption === option.id;

                        return (
                          <div
                            key={option.id}
                            className={`p-4 rounded-lg border ${
                              isSelected
                                ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                                : "border-gray-200 dark:border-gray-700"
                            }`}
                          >
                            <div className="flex justify-between items-center mb-2">
                              <span
                                className={`font-medium ${
                                  isSelected
                                    ? "text-blue-700 dark:text-blue-300"
                                    : "text-gray-900 dark:text-white"
                                }`}
                              >
                                {option.label} {isSelected && "(Your choice)"}
                              </span>
                              <span className="text-sm text-gray-600 dark:text-gray-400">
                                {votes} votes ({percentage}%)
                              </span>
                            </div>
                            <Progress value={percentage} className="h-2" />
                          </div>
                        );
                      })}
                  </div>

                  {/* Action buttons */}
                  <div className="flex gap-3 pt-4">
                    <Link href="/polls" className="flex-1">
                      <Button variant="outline" className="w-full">
                        View More Polls
                      </Button>
                    </Link>
                    <Button
                      variant="outline"
                      onClick={() => {
                        navigator.clipboard.writeText(window.location.href);
                      }}
                      className="flex-1"
                    >
                      Share Poll
                    </Button>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Poll metadata */}
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Poll created on {new Date(poll.created_at).toLocaleDateString()}
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
