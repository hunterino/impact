import { corsHeaders } from "../_shared/cors.ts";
import { getUserFromReq } from "../_shared/clientSupabase.ts";
import { serverSupabase } from "../_shared/serverSupabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const user = await getUserFromReq(req);
  if (!user) {
    throw new Error("Missing user information");
  }

  const { projectEventId } = await req.json();
  if (!projectEventId) {
    throw new Error("Missing projectEventId");
  }

  return new Response(JSON.stringify({ status: "API DECOMMISSIONED" }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
  /*
    // Verify user is an admin of the project
    const { data: projectEvent, error: projectEventError } = await serverSupabase
      .from('project_event')
      .select(`
        *,
        project (
          *
        )
      `)
      .eq('id', projectEventId)
      .single()
    console.log('db project_event')
  
    if (projectEventError) {
      throw projectEventError
    }
  
    if (projectEvent.project?.owner_id !== user.id) {
      throw new Error('User is not an admin of the project')
    }
  
    // Retrieve data
    const { data: res, error } = await serverSupabase
      .from('project_event_commitment')
      .select(`
        commitment_start,
        commitment_end,
        role,
        profile (
          handle,
          sensitive_profile (
            first_name,
            last_name,
            email
          )
        )
        `)
      .eq('project_event_id', projectEventId)
  
    if (error) {
      throw error
    }
  
    try {
      return new Response(JSON.stringify(res), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } catch (error: any) {
      return new Response(JSON.stringify({ error: error.message }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      });
    }
      */
});
