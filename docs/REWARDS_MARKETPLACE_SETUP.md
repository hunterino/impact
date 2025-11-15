# Rewards Marketplace Setup Complete

## Overview
The rewards marketplace database infrastructure has been successfully implemented with comprehensive tables, functions, and sample data.

## What Was Built

### 1. Database Tables

#### **wallet_balance** (Enhanced)
- Added `serv_dr_balance` (decimal) - SERV DR currency balance
- Added `serv_coin_balance` (decimal) - SERV Coin balance
- Added `serv_coin_wallet_active` (boolean) - Wallet activation status
- Constraints ensure all balances are non-negative

####  **rewards**
Complete rewards catalog table with:
- `id`, `title`, `description`
- `category` - Retail, Dining, Entertainment, Gift Cards, Travel, Services
- `serv_dr_cost` - Cost in SERV DR currency
- `retail_value` - Actual retail value
- `image_url` - Product image
- `vendor_name`, `vendor_id`
- `stock_quantity` - (-1 = unlimited stock)
- `is_active` - Enable/disable rewards
- RLS policies for security

#### **redemptions**
Tracks user reward redemptions:
- `user_id`, `reward_id`
- `status` - pending, processing, fulfilled, cancelled, expired
- `redemption_code` - Unique code for each redemption
- `fulfillment_instructions`
- `redemption_date`, `fulfilled_at`, `expires_at`
- RLS policies for user privacy

#### **transactions** (Enhanced)
- Added `category` - points, serv_dr, serv_coin, conversion, redemption
- Added `currency` - points, serv_dr, serv_coin
- Added `conversion_rate` - For tracking currency conversions

### 2. Database Functions

#### **convert_points_to_serv_dr(user_id, points_amount)**
- Conversion rate: 100 STBF Points = 1 SERV DR
- Atomically deducts points and credits SERV DR
- Creates transaction record
- Returns transaction ID

#### **convert_serv_dr_to_serv_coin(user_id, serv_dr_amount)**
- Conversion rate: 1 SERV DR = 1 SERV Coin
- Requires activated SERV Coin wallet
- Atomically deducts SERV DR and credits SERV Coin
- Creates transaction record

#### **activate_serv_coin_wallet(user_id)**
- Activates SERV Coin wallet for user
- Required before converting SERV DR to SERV Coin

#### **redeem_reward_atomic(user_id, reward_id)**
- Validates reward is active and in stock
- Checks user has sufficient SERV DR balance
- Atomically:  - Deducts SERV DR from wallet
  - Decrements reward stock
  - Creates redemption with unique code
  - Creates transaction record
- Returns redemption ID

#### **get_user_wallet_summary(user_id)**
- Returns complete wallet information as JSON
- Includes all balances and activation status

### 3. Sample Data

**20 Rewards Added** across all categories:
- 3x Gift Cards (Amazon, Starbucks, Target, Best Buy)
- 3x Dining (Chipotle, DoorDash, Panera)
- 4x Entertainment (Netflix, Movie Tickets, iTunes, Spotify)
- 3x Retail (Nike, Walmart, Bath & Body Works)
- 2x Travel (Airbnb, Uber, Southwest)
- 2x Services (Gym Membership, Car Wash)
- 3x High-value items (AirPods, etc.)

Rewards range from **5 SERV DR to 100 SERV DR**

### 4. Security (RLS Policies)

- Users can only view their own wallet and transactions
- Users can only view their own redemptions
- All users can view active rewards
- Only admins can manage (add/edit/delete) rewards
- Functions are SECURITY DEFINER for safe privilege escalation

## Database Migrations Applied

1. `20250530000004_create_rewards_marketplace.sql` - Main schema
2. `20250530000005_seed_sample_rewards.sql` - Sample data

## Currency Flow

```
STBF Points (earned through volunteer service)
    ↓ (100 points = 1 SERV DR)
SERV DR (marketplace currency)
    ↓ (requires wallet activation, 1:1 ratio)
SERV Coin (blockchain currency - future)
```

## Next Steps

### Required for MVP:

1. **Update RewardsService** to use Supabase directly instead of MQTT
   - Replace MQTT requests with Supabase function calls
   - Use the RPC functions we created
   - Update Provider methods

2. **Test Wallet Functionality**
   - Create test user with points balance
   - Test Points → SERV DR conversion
   - Test SERV Coin wallet activation
   - Test SERV DR → SERV Coin conversion

3. **Test Rewards Marketplace Screen**
   - Load rewards from database
   - Filter by category and cost
   - View reward details
   - Test redemption flow

4. **Add Initial User Wallet**
   - Create trigger to auto-create wallet on user signup
   - Seed test user with initial points balance for testing

### Optional Enhancements:

1. **Admin Panel**
   - UI for adding/editing rewards
   - Manage reward stock
   - View redemption analytics

2. **Email Notifications**
   - Send redemption codes via email
   - Send fulfillment instructions
   - Notify when rewards are fulfilled

3. **Real Product Images**
   - Replace placeholder images with actual product images
   - Add image upload functionality

4. **Advanced Features**
   - Redemption expiration handling
   - Auto-fulfill digital rewards
   - Integration with actual vendors (Gift card APIs)
   - Blockchain integration for SERV Coin

## Testing the Database

### Query rewards:
```sql
SELECT title, category, serv_dr_cost, stock_quantity
FROM public.rewards
WHERE is_active = true
ORDER BY category, serv_dr_cost;
```

### Check wallet:
```sql
SELECT * FROM get_user_wallet_summary('user-id-here');
```

### Test conversion:
```sql
SELECT convert_points_to_serv_dr('user-id-here', 1000);
-- Converts 1000 points to 10 SERV DR
```

### Test redemption:
```sql
SELECT redeem_reward_atomic('user-id-here', 'reward-id-here');
```

## Files Created

- `/supabase/migrations/20250530000004_create_rewards_marketplace.sql`
- `/supabase/migrations/20250530000005_seed_sample_rewards.sql`
- `/docs/REWARDS_MARKETPLACE_SETUP.md` (this file)

## Notes

- The `supabase db reset` command had issues with the migration
- Migrations were applied directly using `psql` successfully
- All 20 sample rewards are in the database and ready for testing
- RLS policies are enabled for all tables
- All functions have proper error handling and validation
