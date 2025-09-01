import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function HomePage() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-16">
        {/* Hero Section */}
        <div className="text-center mb-16">
          <h1 className="text-5xl font-bold text-gray-900 dark:text-white mb-4">
            Welcome to DevCon
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-300 mb-8 max-w-2xl mx-auto">
            Connect with developers, share insights, and participate in community polls
            to shape the future of technology.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/polls">
              <Button size="lg" className="px-8 py-3 text-lg">
                View Polls
              </Button>
            </Link>
            <Button variant="outline" size="lg" className="px-8 py-3 text-lg">
              Learn More
            </Button>
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-3 gap-8 mb-16">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
            <div className="text-3xl mb-4">🗳️</div>
            <h3 className="text-xl font-semibold mb-2 text-gray-900 dark:text-white">
              Community Polls
            </h3>
            <p className="text-gray-600 dark:text-gray-300">
              Participate in developer polls and help shape the community's decisions
              on frameworks, tools, and best practices.
            </p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
            <div className="text-3xl mb-4">👥</div>
            <h3 className="text-xl font-semibold mb-2 text-gray-900 dark:text-white">
              Developer Community
            </h3>
            <p className="text-gray-600 dark:text-gray-300">
              Connect with like-minded developers from around the world and share
              your experiences and knowledge.
            </p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
            <div className="text-3xl mb-4">🚀</div>
            <h3 className="text-xl font-semibold mb-2 text-gray-900 dark:text-white">
              Stay Updated
            </h3>
            <p className="text-gray-600 dark:text-gray-300">
              Keep up with the latest trends in technology and get insights from
              industry experts and fellow developers.
            </p>
          </div>
        </div>

        {/* Call to Action */}
        <div className="text-center">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-8 shadow-md max-w-2xl mx-auto">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Ready to get started?
            </h2>
            <p className="text-gray-600 dark:text-gray-300 mb-6">
              Jump into our active polling system and make your voice heard in the
              developer community.
            </p>
            <Link href="/polls">
              <Button size="lg" className="px-8 py-3 text-lg">
                Explore Polls →
              </Button>
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}
