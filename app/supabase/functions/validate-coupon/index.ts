import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0"

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
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { code, cart_total, user_id } = await req.json()

    if (!code || !cart_total || !user_id) {
      return new Response(
        JSON.stringify({ valid: false, message: 'Missing parameters' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // Since coupon select is allowed by active = true, we can query it directly
    const { data: coupon, error } = await supabaseClient
      .from('coupons')
      .select('*')
      .eq('code', code)
      .eq('is_active', true)
      .single()

    if (error || !coupon) {
      return new Response(
        JSON.stringify({ valid: false, message: 'Invalid or expired coupon' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    const now = new Date()
    const validFrom = coupon.valid_from ? new Date(coupon.valid_from) : null
    const validTo = coupon.valid_to ? new Date(coupon.valid_to) : null

    if (validFrom && now < validFrom) {
      return new Response(
        JSON.stringify({ valid: false, message: 'Coupon not yet active' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    if (validTo && now > validTo) {
      return new Response(
        JSON.stringify({ valid: false, message: 'Coupon expired' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    if (coupon.used_count >= coupon.max_uses) {
      return new Response(
        JSON.stringify({ valid: false, message: 'Coupon limit reached' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    if (cart_total < coupon.min_order) {
      return new Response(
        JSON.stringify({ valid: false, message: `Minimum order value should be ₹${coupon.min_order}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    let discount_amount = 0
    if (coupon.type === 'flat' || coupon.type === 'cashback') {
      discount_amount = coupon.value
    } else if (coupon.type === 'percent') {
      discount_amount = (cart_total * coupon.value) / 100
      // In a real app we might cap max discount
    } else if (coupon.type === 'free_delivery') {
      discount_amount = coupon.value // Assume value holds base delivery charge
    }

    const final_total = Math.max(0, cart_total - discount_amount)

    return new Response(
      JSON.stringify({
        valid: true,
        discount_amount,
        final_total,
        message: 'Coupon applied successfully',
        coupon_type: coupon.type
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
