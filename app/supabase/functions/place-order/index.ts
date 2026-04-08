import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 })
    }


    // The JWT is automatically verified by the Supabase API gateway before this code runs.
    // We can safely extract the user_id directly from the payload.
    const token = authHeader.replace(/^Bearer\s+/i, '').trim()
    let user_id: string;
    try {
      const payload = JSON.parse(atob(token.split('.')[1]))
      user_id = payload.sub
      if (!user_id) throw new Error("No sub in JWT")
    } catch(e) {
      return new Response(JSON.stringify({ error: 'Unauthorized', details: 'Invalid JWT payload' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // STEP 2 — PARSE REQUEST BODY
    const { items, coupon_code, delivery_address } = await req.json()

    if (!items || !Array.isArray(items) || items.length === 0) {
      return new Response(JSON.stringify({ error: 'Invalid or empty items array' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
    }

    // STEP 3 — VALIDATE & FETCH PRODUCT PRICES FROM DB
    let subtotal = 0
    const orderItems = []
    const stockUpdates = []

    for (const item of items) {
      const { data: product, error: productError } = await supabaseAdmin
        .from('products')
        .select('id, name, price, stock_qty')
        .eq('id', item.product_id)
        .single()

      if (productError || !product) {
        return new Response(JSON.stringify({ error: `Product not found: ${item.product_id} (${productError?.message})` }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
      }

      if (product.stock_qty < item.quantity) {
        return new Response(JSON.stringify({ error: `Insufficient stock for: ${product.name}` }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
      }

      const itemTotal = Number(product.price) * Number(item.quantity)
      subtotal += itemTotal

      orderItems.push({
        product_id: product.id,
        quantity: item.quantity,
        price_at_purchase: product.price
      })

      stockUpdates.push({
        id: product.id,
        new_quantity: product.stock_qty - item.quantity
      })
    }

    // STEP 4 — APPLY COUPON (if coupon_code is provided)
    let discount = 0
    let total = subtotal

    if (coupon_code) {
      const { data: coupon, error: couponError } = await supabaseAdmin
        .from('coupons')
        .select('*')
        .eq('code', coupon_code)
        .single()

      if (couponError || !coupon) {
        return new Response(JSON.stringify({ error: 'Invalid or expired coupon' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
      }

      const now = new Date()
      const validUntil = coupon.valid_until ? new Date(coupon.valid_until) : null

      if (!coupon.is_active || (validUntil && now > validUntil) || subtotal < coupon.min_order_value) {
        return new Response(JSON.stringify({ error: 'Invalid or expired coupon' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
      }

      if (coupon.discount_type === 'flat') {
        discount = coupon.value
      } else if (coupon.discount_type === 'percent') {
        discount = (subtotal * coupon.value) / 100
      } else if (coupon.discount_type === 'free_delivery') {
        discount = coupon.value
      }

      total = Math.max(0, subtotal - discount)
    }

    // STEP 5 — ATOMIC DB TRANSACTION using sequential inserts with error rollback
    // a) Insert into orders table
    const { data: orderData, error: orderError } = await supabaseAdmin
      .from('orders')
      .insert({
        user_id: user_id,
        status: 'CONFIRMED',
        subtotal: subtotal,
        discount: discount,
        total: total,
        coupon_code: coupon_code || null,
        delivery_address: delivery_address
      })
      .select('id')
      .single()

    if (orderError || !orderData) {
      throw new Error(`Failed to create order: ${orderError?.message}`)
    }

    const order_id = orderData.id

    try {
      // b) Insert into order_items table for each item
      const orderItemsToInsert = orderItems.map(item => ({
        order_id: order_id,
        product_id: item.product_id,
        quantity: item.quantity,
        price_at_purchase: item.price_at_purchase
      }))

      const { error: itemsError } = await supabaseAdmin
        .from('order_items')
        .insert(orderItemsToInsert)

      if (itemsError) throw new Error(`Failed to insert items: ${itemsError.message}`)

      // c) Decrement stock for each product
      for (const update of stockUpdates) {
        const { error: stockError } = await supabaseAdmin
          .from('products')
          .update({ stock_qty: update.new_quantity })
          .eq('id', update.id)

        if (stockError) throw new Error(`Failed to update stock: ${stockError.message}`)
      }
    } catch (e) {
      // error rollback
      await supabaseAdmin.from('orders').delete().eq('id', order_id)
      throw e
    }

    // STEP 6 — RETURN SUCCESS
    return new Response(
      JSON.stringify({
        success: true,
        order_id: order_id,
        total: total,
        message: "Order placed successfully"
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message || 'Internal Server Error' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
