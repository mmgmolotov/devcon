-- Create polls table
CREATE TABLE IF NOT EXISTS polls (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create poll_options table
CREATE TABLE IF NOT EXISTS poll_options (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  option_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create votes table
CREATE TABLE IF NOT EXISTS votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  option_id UUID REFERENCES poll_options(id) ON DELETE CASCADE,
  user_id TEXT, -- For anonymous voting, we'll use session/IP
  user_session TEXT, -- Browser session identifier
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Prevent duplicate votes from same user/session
  UNIQUE(poll_id, user_session)
);

-- Create view for poll results
CREATE OR REPLACE VIEW poll_results AS
SELECT
  p.id as poll_id,
  p.title,
  p.description,
  p.category,
  p.is_active,
  po.id as option_id,
  po.label as option_label,
  po.option_order,
  COUNT(v.id) as vote_count,
  p.created_at
FROM polls p
LEFT JOIN poll_options po ON p.id = po.poll_id
LEFT JOIN votes v ON po.id = v.option_id
GROUP BY p.id, p.title, p.description, p.category, p.is_active, po.id, po.label, po.option_order, p.created_at
ORDER BY p.created_at DESC, po.option_order ASC;

-- Create view for poll summaries
CREATE OR REPLACE VIEW poll_summaries AS
SELECT
  p.id,
  p.title,
  p.description,
  p.category,
  p.is_active,
  p.created_at,
  COUNT(DISTINCT v.id) as total_votes,
  COUNT(DISTINCT po.id) as total_options
FROM polls p
LEFT JOIN poll_options po ON p.id = po.poll_id
LEFT JOIN votes v ON po.id = v.option_id
GROUP BY p.id, p.title, p.description, p.category, p.is_active, p.created_at
ORDER BY p.created_at DESC;

-- Enable RLS (Row Level Security)
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Allow public read access on polls" ON polls
  FOR SELECT USING (true);

CREATE POLICY "Allow public read access on poll_options" ON poll_options
  FOR SELECT USING (true);

CREATE POLICY "Allow public read access on votes" ON votes
  FOR SELECT USING (true);

-- Create policies for voting (insert only)
CREATE POLICY "Allow public insert on votes" ON votes
  FOR INSERT WITH CHECK (true);

-- Insert sample data
INSERT INTO polls (id, title, description, category) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'What''s your favorite frontend framework?', 'Help us understand the current preferences in frontend development among our developer community.', 'Frontend'),
  ('550e8400-e29b-41d4-a716-446655440002', 'Which language do you prefer for backend development?', 'Share your backend language preference for modern web applications and APIs.', 'Backend'),
  ('550e8400-e29b-41d4-a716-446655440003', 'Best CSS-in-JS library for React?', 'What''s your go-to styling solution when working with React applications?', 'Styling');

INSERT INTO poll_options (poll_id, label, option_order) VALUES
  -- Frontend framework options
  ('550e8400-e29b-41d4-a716-446655440001', 'React', 1),
  ('550e8400-e29b-41d4-a716-446655440001', 'Vue.js', 2),
  ('550e8400-e29b-41d4-a716-446655440001', 'Svelte', 3),
  ('550e8400-e29b-41d4-a716-446655440001', 'Angular', 4),

  -- Backend language options
  ('550e8400-e29b-41d4-a716-446655440002', 'Node.js', 1),
  ('550e8400-e29b-41d4-a716-446655440002', 'Python', 2),
  ('550e8400-e29b-41d4-a716-446655440002', 'Go', 3),
  ('550e8400-e29b-41d4-a716-446655440002', 'Rust', 4),
  ('550e8400-e29b-41d4-a716-446655440002', 'Java', 5),

  -- CSS-in-JS options
  ('550e8400-e29b-41d4-a716-446655440003', 'Styled Components', 1),
  ('550e8400-e29b-41d4-a716-446655440003', 'Emotion', 2),
  ('550e8400-e29b-41d4-a716-446655440003', 'CSS Modules', 3),
  ('550e8400-e29b-41d4-a716-446655440003', 'Tailwind CSS', 4);

-- Add some sample votes for demonstration
INSERT INTO votes (poll_id, option_id, user_session) VALUES
  -- Frontend framework votes
  ('550e8400-e29b-41d4-a716-446655440001', (SELECT id FROM poll_options WHERE poll_id = '550e8400-e29b-41d4-a716-446655440001' AND label = 'React'), 'demo-session-1'),
  ('550e8400-e29b-41d4-a716-446655440001', (SELECT id FROM poll_options WHERE poll_id = '550e8400-e29b-41d4-a716-446655440001' AND label = 'React'), 'demo-session-2'),
  ('550e8400-e29b-41d4-a716-446655440001', (SELECT id FROM poll_options WHERE poll_id = '550e8400-e29b-41d4-a716-446655440001' AND label = 'Vue.js'), 'demo-session-3'),

  -- Backend language votes
  ('550e8400-e29b-41d4-a716-446655440002', (SELECT id FROM poll_options WHERE poll_id = '550e8400-e29b-41d4-a716-446655440002' AND label = 'Python'), 'demo-session-4'),
  ('550e8400-e29b-41d4-a716-446655440002', (SELECT id FROM poll_options WHERE poll_id = '550e8400-e29b-41d4-a716-446655440002' AND label = 'Node.js'), 'demo-session-5');
