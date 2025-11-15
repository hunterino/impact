import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

const VERIFY_API_SECRET = Deno.env.get('VERIFY_API_SECRET')

interface VerifyTransactionRequest {
  confirmationCode: string
  orderTotal: number
  orderId?: string
}

interface VerifyTransactionResponse {
  success: boolean
  transactionId?: string
  message?: string
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
    const { confirmationCode, orderTotal, orderId }: VerifyTransactionRequest = await req.json()

    if (!confirmationCode) {
      return new Response(
        JSON.stringify({ success: false, message: 'Missing confirmation code' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Find the transaction by confirmation code
    const { data: transaction, error: txError } = await supabase
      .from('transactions')
      .select('*')
      .eq('confirmation_code', confirmationCode)
      .eq('type', 'debit')
      .single()

    if (txError || !transaction) {
      return new Response(
        JSON.stringify({ success: false, message: 'Invalid confirmation code' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check transaction status
    if (transaction.status !== 'pending') {
      return new Response(
        JSON.stringify({ success: false, message: 'Transaction already processed or cancelled' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify amount matches (if provided)
    if (orderTotal && transaction.amount !== orderTotal) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: `Amount mismatch. Expected: ${transaction.amount}, Received: ${orderTotal}` 
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if transaction is expired (15 minutes)
    const createdAt = new Date(transaction.created_at)
    const now = new Date()
    const diffMinutes = (now.getTime() - createdAt.getTime()) / (1000 * 60)
    
    if (diffMinutes > 15) {
      // Transaction expired, cancel and refund
      await supabase.rpc('cancel_transaction_atomic', {
        p_transaction_id: transaction.id,
        p_reason: 'expired'
      })

      return new Response(
        JSON.stringify({ success: false, message: 'Transaction expired' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Mark transaction as completed
    const { error: updateError } = await supabase
      .from('transactions')
      .update({ 
        status: 'completed',
        order_id: orderId || transaction.order_id,
        updated_at: new Date().toISOString()
      })
      .eq('id', transaction.id)

    if (updateError) {
      console.error('Failed to update transaction:', updateError)
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to complete transaction' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const response: VerifyTransactionResponse = {
      success: true,
      transactionId: transaction.id,
      message: 'Transaction verified and completed'
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in verify-transaction:', error)
    return new Response(
      JSON.stringify({ success: false, message: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
