import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

interface RedeemPointsRequest {
  amount: number
  orderId?: string
}

interface RedeemPointsResponse {
  success: boolean
  confirmationCode?: string
  transactionId?: string
  message?: string
}

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    // Get user from auth token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, message: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, message: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { amount, orderId }: RedeemPointsRequest = await req.json()

    if (!amount || amount <= 0) {
      return new Response(
        JSON.stringify({ success: false, message: 'Invalid amount' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Start database transaction
    const { data: walletData, error: walletError } = await supabase
      .from('wallet_balance')
      .select('balance')
      .eq('user_id', user.id)
      .single()

    if (walletError) {
      if (walletError.code === 'PGRST116') {
        // No wallet found, create one with 0 balance
        const { error: createError } = await supabase
          .from('wallet_balance')
          .insert({ user_id: user.id, balance: 0 })

        if (createError) {
          throw new Error('Failed to create wallet')
        }

        return new Response(
          JSON.stringify({ success: false, message: 'Insufficient balance' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      throw walletError
    }

    // Check if user has sufficient balance
    if (walletData.balance < amount) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Insufficient balance',
          currentBalance: walletData.balance,
          required: amount
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate unique confirmation code
    const confirmationCode = crypto.randomUUID()

    // Perform atomic transaction: deduct balance and create transaction record
    const { data: transactionData, error: transactionError } = await supabase.rpc(
      'redeem_points_atomic',
      {
        p_user_id: user.id,
        p_amount: amount,
        p_order_id: orderId || null,
        p_confirmation_code: confirmationCode
      }
    )

    if (transactionError) {
      console.error('Transaction error:', transactionError)
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to process redemption' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const response: RedeemPointsResponse = {
      success: true,
      confirmationCode,
      transactionId: transactionData,
      message: 'Points redeemed successfully'
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in redeem-points:', error)
    return new Response(
      JSON.stringify({ success: false, message: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
