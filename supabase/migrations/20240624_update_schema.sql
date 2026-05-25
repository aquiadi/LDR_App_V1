-- 20240624_update_schema.sql

-- 0. Fix past schema discrepancies to match Flutter models


-- 1. Add last_seen to users table for lightweight presence
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS last_seen timestamp with time zone DEFAULT now();

-- 2. Create relationship_pings table
CREATE TABLE IF NOT EXISTS public.relationship_pings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
    sender_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    receiver_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pings_couple_created ON public.relationship_pings (couple_id, created_at DESC);

ALTER TABLE public.relationship_pings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pings_couple_access" ON public.relationship_pings
    USING (
        auth.uid() IN (
            SELECT partner_1_id FROM public.couples WHERE id = couple_id
            UNION
            SELECT partner_2_id FROM public.couples WHERE id = couple_id
        )
    );
CREATE POLICY "pings_insert" ON public.relationship_pings
    FOR INSERT WITH CHECK (auth.uid() = sender_id);


-- 3. Create daily_prompt_answers table
CREATE TABLE IF NOT EXISTS public.daily_prompt_answers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    prompt_date date NOT NULL DEFAULT CURRENT_DATE,
    prompt_text text NOT NULL,
    answer_text text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(user_id, prompt_date)
);

CREATE INDEX IF NOT EXISTS idx_prompts_couple_date ON public.daily_prompt_answers (couple_id, prompt_date DESC);

ALTER TABLE public.daily_prompt_answers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prompts_couple_access" ON public.daily_prompt_answers
    USING (
        auth.uid() IN (
            SELECT partner_1_id FROM public.couples WHERE id = couple_id
            UNION
            SELECT partner_2_id FROM public.couples WHERE id = couple_id
        )
    );
CREATE POLICY "prompts_modify" ON public.daily_prompt_answers
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "prompts_update" ON public.daily_prompt_answers
    FOR UPDATE USING (auth.uid() = user_id);


-- 4. Create countdown_events table
CREATE TABLE IF NOT EXISTS public.countdown_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id uuid NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
    creator_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    target_date timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_countdowns_couple_target ON public.countdown_events (couple_id, target_date ASC);

ALTER TABLE public.countdown_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "countdowns_couple_access" ON public.countdown_events
    USING (
        auth.uid() IN (
            SELECT partner_1_id FROM public.couples WHERE id = couple_id
            UNION
            SELECT partner_2_id FROM public.couples WHERE id = couple_id
        )
    );
CREATE POLICY "countdowns_modify" ON public.countdown_events
    FOR ALL USING (
        auth.uid() IN (
            SELECT partner_1_id FROM public.couples WHERE id = couple_id
            UNION
            SELECT partner_2_id FROM public.couples WHERE id = couple_id
        )
    );

-- Enable realtime for new tables
alter publication supabase_realtime add table public.relationship_pings;
alter publication supabase_realtime add table public.daily_prompt_answers;
alter publication supabase_realtime add table public.countdown_events;
