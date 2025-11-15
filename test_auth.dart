import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );

  final supabase = Supabase.instance.client;

  try {
    print('Testing authentication with ds@coyoteforge.com...');

    // Sign in with email and password
    final response = await supabase.auth.signInWithPassword(
      email: 'ds@coyoteforge.com',
      password: 'all4Datastore!',
    );

    if (response.user != null) {
      print('✅ Authentication successful!');
      print('User ID: ${response.user!.id}');
      print('Email: ${response.user!.email}');
      print('Session token: ${response.session?.accessToken?.substring(0, 20)}...');

      // Fetch profile
      final profile = await supabase
          .from('profile')
          .select()
          .eq('user_id', response.user!.id)
          .single();

      print('Handle: ${profile['handle']}');

      // Fetch wallet balance
      final wallet = await supabase
          .from('wallet_balance')
          .select()
          .eq('user_id', response.user!.id)
          .single();

      print('STBF Points: ${wallet['balance']}');

      // Sign out
      await supabase.auth.signOut();
      print('✅ Signed out successfully');
    } else {
      print('❌ Authentication failed');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}