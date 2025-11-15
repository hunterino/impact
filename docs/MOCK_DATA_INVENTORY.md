# Mock Data Inventory - Serve To Be Free Flutter App

This document catalogs all hardcoded/mock data currently in the application that should be replaced with real backend data.

## Overview Summary

**Total Mock Data Points: 100+ instances**
**Affected Screens: 5 main screens**
**Priority for Backend Integration: HIGH**

---

## 1. Dashboard Screen
**File:** `lib/features/home/screens/dashboard_screen.dart`

### Statistics Cards (Lines 134-176)
- **Service Hours:** `'124'` (Line 139)
- **Projects:** `'15'` (Line 148)
- **Points Earned:** `'2,450'` (Line 161)
- **Teams:** `'3'` (Line 170)

### Recent Activity (Lines 351-371)
- **Beach Cleanup:** "Completed Beach Cleanup" - 2 hours logged • 2 days ago
- **Points Achievement:** "Earned 100 points" - Level up achievement • 3 days ago
- **Team Activity:** "Joined Team Green Warriors" - New team member • 5 days ago

### Upcoming Events (Lines 428-441)
- **Event 1:** "Community Garden Project" - Tomorrow, 9:00 AM - Central Park - 12 participants
- **Event 2:** "Food Bank Volunteer" - Sat, Nov 16, 10:00 AM - Downtown Food Bank - 8 participants

---

## 2. Profile Screen
**File:** `lib/features/profile/screens/profile_screen.dart`

### Profile Stats (Lines 144-165)
- **Projects:** `'12'` (Line 146)
- **Hours:** `'45.5'` (Line 155)
- **Points:** `'4,550'` (Line 164)

### Skills (Line 196)
- Hardcoded skills list: ["Teaching", "Gardening", "Construction", "Cooking"]

---

## 3. Projects Screen
**File:** `lib/features/service_opportunities/screens/projects_screen.dart`

### Filter Values (Lines 219-236)
- Status options: `['upcoming', 'active', 'completed']`

### Status Labels (Lines 628-640)
- `'Completed'`, `'In Progress'`, `'Upcoming'`, `'Open'`

---

## 4. Community Screen
**File:** `lib/features/community/screens/community_screen.dart`

### Feed Tab (Lines 71-223)
**Mock Posts (10 items):**
- User: "John Doe" (JD) - "2 hours ago"
- Content: "Just finished an amazing day volunteering at the food bank..."
- Likes: 24, 27, 30... (increments by 3)
- Comments: 5, 6, 7... (increments by 1)
- Achievement: "Completed 100 service hours"
- Project: "Beach Cleanup Drive" - Tomorrow at 9:00 AM

### Teams Tab (Lines 257-274)
**5 Mock Teams:**
1. Green Warriors - 12 members - 2450 points
2. Community Heroes - 8 members - 1890 points
3. Beach Guardians - 15 members - 3200 points
4. Food Bank Squad - 20 members - 4100 points
5. Youth Mentors - 6 members - 950 points

### Leaderboard Tab (Lines 404-526)
**Top 3:**
1. Mike R. - 2100 points
2. Sarah J. - 1850 points
3. Lisa M. - 1650 points

**Positions 4-10:**
- David K. - 1500 points
- Emma S. - 1450 points
- Chris P. - 1400 points
- Anna B. - 1350 points
- Tom W. - 1300 points
- Rachel G. - 1250 points
- James T. - 1200 points

---

## 5. Rewards Screen
**File:** `lib/features/rewards/screens/rewards_screen.dart`

### Balance Card (Lines 124-203)
- **STBF Points:** `'2,450'`
- **Trend:** `'+150 this month'`
- **ServDr:** `'245'`
- **Pending:** `'50'`
- **Lifetime:** `'5.2K'`

### Points Breakdown (Lines 384-408)
- Service Hours: 1200 points (49%)
- Project Completion: 800 points (33%)
- Team Activities: 300 points (12%)
- Achievements: 150 points (6%)

### Recent Rewards (Lines 505-530)
1. Coffee Shop Voucher - Local Coffee Co. - 2 days ago - 150 points
2. Movie Ticket - CineMax - 1 week ago - 300 points
3. Bookstore Discount - ReadMore Books - 2 weeks ago - 100 points

### Transaction History (Lines 573-614)
**15 Mock Transactions cycling through 4 types:**
- Volunteer at Food Bank - 3 hours • Service - +30 points
- Coffee Voucher Redeemed - Local Coffee Co. - -150 points
- Project Completion Bonus - Beach Cleanup - +50 points
- Converted to ServDr - Currency Exchange - -100 points

---

## Backend Integration Priority

### High Priority (Core Functionality)
1. **User Profile Data** - Real user stats and info
2. **Service Hours & Projects** - Actual volunteer data
3. **Points Balance** - Real rewards system data
4. **Teams Data** - Actual team memberships and stats

### Medium Priority (Engagement Features)
1. **Feed Posts** - Real community activity
2. **Leaderboard** - Live rankings
3. **Transaction History** - Real points/rewards history
4. **Upcoming Events** - Live event data

### Low Priority (Can remain mock initially)
1. **UI Labels and Placeholders**
2. **Filter Options** (unless dynamic)
3. **Static Category Lists**

---

## Implementation Notes

### Data Sources
All real data should come from:
1. **Supabase Database** for persistent data
2. **MQTT Topics** for real-time updates
3. **Provider Pattern** for state management

### Existing Services Ready for Integration:
- `AuthService` - User authentication ✓ (Working)
- `UserService` - User profile data
- `ProjectService` - Projects and events
- `VolunteerService` - Service hours and teams
- `RewardsService` - Points and rewards

### Database Tables Needed:
- `profile` ✓ (Exists)
- `wallet_balance` ✓ (Exists)
- `projects` (To be created)
- `teams` (To be created)
- `service_hours` (To be created)
- `rewards` (To be created)
- `transactions` (To be created)
- `posts` (To be created)
- `leaderboard` (View or computed)

---

## Next Steps
1. Create missing database tables in Supabase
2. Implement data fetching in providers
3. Replace mock data with provider calls
4. Set up MQTT subscriptions for real-time updates
5. Add loading states and error handling
6. Implement data caching for offline support