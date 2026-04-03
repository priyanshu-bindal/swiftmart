import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0"
import * as postgres from "https://deno.land/x/postgres@v0.17.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Get the connection string from Supabase environment variables (Direct connection)
const databaseUrl = Deno.env.get('SUPABASE_DB_URL')!

// Create a connection pool
const pool = new postgres.Pool(databaseUrl, 3, true)

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing Auth Header')
    }

    // Initialize supabase client to verify user
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    
    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    const { items, address_id, coupon_code, total, discount, payment_method, subtotal } = await req.json()

    // Grab a connection from the pool
    const connection = await pool.connect()

    try {
      // Start Transaction
      await connection.queryObject`BEGIN`

      // 1. Validate items and sufficient stock
      for (const item of items) {
        const result = await connection.queryObject`
          SELECT stock_qty FROM products WHERE id = ${item.product_id} FOR UPDATE
        `
        const stockQty = result.rows[0]?.stock_qty as number
        if (stockQty < item.quantity) {
          throw new Error(`Insufficient stock for product ${item.name}`)
        }
      }

      // 2. Insert order row
      const orderInsert = await connection.queryObject`
        INSERT INTO orders (user_id, status, items, subtotal, discount, total, coupon_code, address_id, payment_method)
        VALUES (${user.id}, 'PENDING', ${JSON.stringify(items)}, ${subtotal}, ${discount}, ${total}, ${coupon_code || null}, ${address_id}, ${payment_method})
        RETURNING id, created_at
      `
      const orderData = orderInsert.rows[0]

      // 3. Deduct stock
      for (const item of items) {
        await connection.queryObject`
          UPDATE products SET stock_qty = stock_qty - ${item.quantity} WHERE id = ${item.product_id}
        `
      }

      // 4. Update coupon usage
      if (coupon_code) {
        await connection.queryObject`
          UPDATE coupons SET used_count = used_count + 1 WHERE code = ${coupon_code}
        `
      }

      // Commit transaction
      await connection.queryObject`COMMIT`

      return new Response(
        JSON.stringify({
          order_id: orderData.id,
          status: 'success',
          created_at: orderData.created_at
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )

    } catch (e) {
      // Rollback transaction on failure
      await connection.queryObject`ROLLBACK`
      throw e
    } finally {
      // Release connection
      connection.release()
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
