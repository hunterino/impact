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

      // Try to fetch profile with detailed error handling
      print('\n--- Testing profile fetch ---');
      try {
        final profileResponse = await supabase
            .from('profile')
            .select()
            .eq('user_id', response.user!.id)
            .single();

        print('✅ Profile fetched successfully:');
        print('Handle: ${profileResponse['handle']}');
        print('Created at: ${profileResponse['created_at']}');
      } catch (profileError) {
        print('❌ Profile fetch error:');
        print('Type: ${profileError.runtimeType}');
        print('Message: $profileError');

        // Try without .single() to see if it's a row count issue
        print('\n--- Trying profile fetch without .single() ---');
        try {
          final profilesList = await supabase
              .from('profile')
              .select()
              .eq('user_id', response.user!.id);

          print('Profile query returned ${profilesList.length} rows');
          if (profilesList.isNotEmpty) {
            print('First profile: ${profilesList[0]}');
          }
        } catch (listError) {
          print('List query also failed: $listError');
        }
      }

      // Try wallet balance
      print('\n--- Testing wallet_balance fetch ---');
      try {
        final walletResponse = await supabase
            .from('wallet_balance')
            .select()
            .eq('user_id', response.user!.id)
            .single();

        print('✅ Wallet balance fetched successfully:');
        print('Balance: ${walletResponse['balance']}');
      } catch (walletError) {
        print('❌ Wallet fetch error: $walletError');
      }

      // Sign out
      await supabase.auth.signOut();
      print('\n✅ Signed out successfully');
    } else {
      print('❌ Authentication failed - no user returned');
    }
  } catch (e) {
    print('❌ Error: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}