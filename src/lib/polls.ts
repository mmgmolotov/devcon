import supabase from '@/auth/supabase';

export interface Poll {
  id: string;
  title: string;
  description: string;
  category: string;
  is_active: boolean;
  created_at: string;
  total_votes: number;
  total_options: number;
}

export interface PollOption {
  id: string;
  label: string;
  option_order: number;
  vote_count: number;
}

export interface PollDetail extends Poll {
  options: PollOption[];
}

export interface VoteData {
  poll_id: string;
  option_id: string;
  user_session: string;
}

// Generate a unique session ID for anonymous voting
export function generateUserSession(): string {
  if (typeof window !== 'undefined') {
    let session = localStorage.getItem('devcon_session');
    if (!session) {
      session = 'session_' + Math.random().toString(36).substring(2, 15) + Date.now();
      localStorage.setItem('devcon_session', session);
    }
    return session;
  }
  return 'server_session_' + Math.random().toString(36).substring(2, 15);
}

// Fetch all polls with summary data
export async function getPolls(): Promise<Poll[]> {
  const { data, error } = await supabase
    .from('poll_summaries')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching polls:', error);
    throw new Error('Failed to fetch polls');
  }

  return data || [];
}

// Fetch a single poll with detailed options and vote counts
export async function getPollById(pollId: string): Promise<PollDetail | null> {
  // Get poll basic info
  const { data: pollData, error: pollError } = await supabase
    .from('polls')
    .select('*')
    .eq('id', pollId)
    .single();

  if (pollError) {
    console.error('Error fetching poll:', pollError);
    return null;
  }

  // Get poll results with vote counts
  const { data: resultsData, error: resultsError } = await supabase
    .from('poll_results')
    .select('*')
    .eq('poll_id', pollId)
    .order('option_order');

  if (resultsError) {
    console.error('Error fetching poll results:', resultsError);
    return null;
  }

  // Calculate total votes
  const totalVotes = resultsData.reduce((sum, option) => sum + option.vote_count, 0);

  // Transform data into expected format
  const options: PollOption[] = resultsData.map(result => ({
    id: result.option_id,
    label: result.option_label,
    option_order: result.option_order,
    vote_count: result.vote_count
  }));

  return {
    id: pollData.id,
    title: pollData.title,
    description: pollData.description,
    category: pollData.category,
    is_active: pollData.is_active,
    created_at: pollData.created_at,
    total_votes: totalVotes,
    total_options: options.length,
    options
  };
}

// Submit a vote for a poll
export async function submitVote(pollId: string, optionId: string): Promise<boolean> {
  const userSession = generateUserSession();

  try {
    const { error } = await supabase
      .from('votes')
      .insert([
        {
          poll_id: pollId,
          option_id: optionId,
          user_session: userSession
        }
      ]);

    if (error) {
      // Check if it's a duplicate vote error
      if (error.code === '23505') {
        throw new Error('You have already voted on this poll');
      }
      console.error('Error submitting vote:', error);
      throw new Error('Failed to submit vote');
    }

    return true;
  } catch (error) {
    console.error('Error in submitVote:', error);
    throw error;
  }
}

// Check if user has already voted on a poll
export async function hasUserVoted(pollId: string): Promise<boolean> {
  const userSession = generateUserSession();

  const { data, error } = await supabase
    .from('votes')
    .select('id')
    .eq('poll_id', pollId)
    .eq('user_session', userSession)
    .limit(1);

  if (error) {
    console.error('Error checking vote status:', error);
    return false;
  }

  return data && data.length > 0;
}

// Get vote counts for a specific poll (for real-time updates)
export async function getPollVoteCounts(pollId: string): Promise<Record<string, number>> {
  const { data, error } = await supabase
    .from('poll_results')
    .select('option_id, vote_count')
    .eq('poll_id', pollId);

  if (error) {
    console.error('Error fetching vote counts:', error);
    return {};
  }

  const voteCounts: Record<string, number> = {};
  data?.forEach(result => {
    voteCounts[result.option_id] = result.vote_count;
  });

  return voteCounts;
}

// Create a real-time subscription for poll results
export function subscribeToPollResults(pollId: string, callback: (payload: any) => void) {
  return supabase
    .channel(`poll_${pollId}`)
    .on('postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'votes',
        filter: `poll_id=eq.${pollId}`
      },
      callback
    )
    .subscribe();
}
