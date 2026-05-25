import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { couple_id } = await req.json()
    if (!couple_id) {
      return new Response(JSON.stringify({ error: 'Missing couple_id' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Initialize Supabase Client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 1. Fetch the last 7 days of check-ins for the couple
    const sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

    const { data: checkins, error: dbError } = await supabaseClient
      .from('daily_checkins')
      .select('*')
      .eq('couple_id', couple_id)
      .gte('created_at', sevenDaysAgo.toISOString())
      .order('created_at', { ascending: true })

    if (dbError) throw dbError

    // Calculate a basic sync percentage and trend manually to ensure structure
    let syncPercentage = 0
    let trendData = [0, 0, 0, 0, 0, 0, 0]
    
    if (checkins && checkins.length > 0) {
        // Mock sync calculation based on the number of checkins
        const avgEnergy = checkins.reduce((acc: number, val: any) => acc + (val.energy_score || 5), 0) / checkins.length
        syncPercentage = Math.min(100, Math.floor(avgEnergy * 10))
        
        // Populate trend data
        for(let i=0; i<Math.min(checkins.length, 7); i++) {
           trendData[i] = (checkins[i].energy_score || 5) * 10
        }
    } else {
        syncPercentage = 50
        trendData = [50, 50, 50, 50, 50, 50, 50]
    }

    // 2. Call OpenAI for insights
    const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')
    
    let catalystPrompt = "Send a voice note to your partner telling them your favorite memory from this week."
    let tips = [
        {
          "icon": "chat_bubble_outline",
          "title": "Communication",
          "desc": "Regular check-ins help maintain emotional closeness."
        },
        {
          "icon": "favorite_border",
          "title": "Affection",
          "desc": "Surprise your partner with a random act of digital kindness today."
        }
    ]

    if (OPENAI_API_KEY) {
        try {
            const openAiRes = await fetch('https://api.openai.com/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${OPENAI_API_KEY}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    model: 'gpt-3.5-turbo',
                    messages: [
                        { role: 'system', content: 'You are an AI relationship coach for a long-distance couple. Based on their recent check-ins, provide 1 actionable "catalyst" suggestion and 2 short "tips" (one about Communication, one about Affection). Return ONLY valid JSON in this exact structure: {"catalystPrompt": "string", "tips": [{"title": "Communication", "desc": "string", "icon": "chat_bubble_outline"}, {"title": "Affection", "desc": "string", "icon": "favorite_border"}]}' },
                        { role: 'user', content: `Here is the couple's checkin data for the last 7 days: ${JSON.stringify(checkins)}` }
                    ],
                    temperature: 0.7,
                })
            })
            
            if (openAiRes.ok) {
                const aiData = await openAiRes.json()
                const aiContent = JSON.parse(aiData.choices[0].message.content)
                catalystPrompt = aiContent.catalystPrompt || catalystPrompt
                tips = aiContent.tips || tips
            }
        } catch (e) {
            console.error("OpenAI Error:", e)
        }
    }

    return new Response(
      JSON.stringify({
          syncPercentage,
          trendData,
          catalystPrompt,
          tips
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
