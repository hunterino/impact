import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

const VERIFY_API_SECRET = Deno.env.get('VERIFY_API_SECRET')

interface CancelTransactionRequest {
  transactionId: string
  reason?: string
}

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    // Verify API secret
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || authHeader !== `Bearer ${VERIFY_API_SECRET}`) {
      return new Response(
        JSON.stringify({ success: false, message: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { transactionId, reason = 'vendure_cancellation' }: CancelTransactionRequest = await req.json()

    if (!transactionId) {
      return new Response(
        JSON.stringify({ success: false, message: 'Missing transaction ID' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Cancel the transaction
    const { data: cancelled, error: cancelError } = await supabase.rpc(
      'cancel_transaction_atomic',
      {
        p_transaction_id: transactionId,
        p_reason: reason
      }
    )

    if (cancelError) {
      console.error('Cancel transaction error:', cancelError)
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to cancel transaction' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        cancelled,
        message: cancelled ? 'Transaction cancelled and refunded' : 'Transaction was already cancelled'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in cancel-transaction:', error)
    return new Response(
      JSON.stringify({ success: false, message: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
