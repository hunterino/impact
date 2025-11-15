-- ================================================
-- SAMPLE REWARDS DATA FOR TESTING
-- ================================================
-- This migration adds sample rewards for marketplace testing

-- Insert sample rewards across different categories
INSERT INTO public.rewards (title, description, category, serv_dr_cost, retail_value, image_url, vendor_name, stock_quantity, is_active, terms_and_conditions)
VALUES
  -- Gift Cards
  (
    '$10 Amazon Gift Card',
    'Digital Amazon.com gift card code delivered via email',
    'Gift Cards',
    5.00,
    10.00,
    'https://via.placeholder.com/300x200?text=Amazon+Gift+Card',
    'Amazon',
    100,
    true,
    'Gift card code will be emailed within 24 hours. Valid for use on Amazon.com only. Not redeemable for cash.'
  ),
  (
    '$25 Starbucks Gift Card',
    'Physical or digital Starbucks gift card',
    'Gift Cards',
    12.50,
    25.00,
    'https://via.placeholder.com/300x200?text=Starbucks+Gift+Card',
    'Starbucks',
    50,
    true,
    'Gift card can be used at any Starbucks location. Choose physical card (shipped) or digital code (emailed).'
  ),
  (
    '$50 Target Gift Card',
    'Target gift card for in-store or online purchases',
    'Gift Cards',
    25.00,
    50.00,
    'https://via.placeholder.com/300x200?text=Target+Gift+Card',
    'Target',
    30,
    true,
    'Valid for purchases at Target stores and Target.com. Cannot be redeemed for cash.'
  ),

  -- Dining
  (
    '$20 Chipotle Gift Card',
    'Enjoy fresh Mexican cuisine at Chipotle',
    'Dining',
    10.00,
    20.00,
    'https://via.placeholder.com/300x200?text=Chipotle+Gift+Card',
    'Chipotle',
    40,
    true,
    'Valid at participating Chipotle locations nationwide. Not redeemable for cash.'
  ),
  (
    '$30 DoorDash Credit',
    'DoorDash credit for food delivery from your favorite restaurants',
    'Dining',
    15.00,
    30.00,
    'https://via.placeholder.com/300x200?text=DoorDash+Credit',
    'DoorDash',
    75,
    true,
    'Credit will be added to your DoorDash account. Subject to DoorDash terms and conditions.'
  ),
  (
    '$15 Panera Bread Gift Card',
    'Fresh bakery and cafe items at Panera Bread',
    'Dining',
    7.50,
    15.00,
    'https://via.placeholder.com/300x200?text=Panera+Gift+Card',
    'Panera Bread',
    60,
    true,
    'Redeemable at participating Panera Bread bakery-cafe locations.'
  ),

  -- Entertainment
  (
    '1-Month Netflix Subscription',
    'One month of Netflix streaming - Standard Plan',
    'Entertainment',
    7.50,
    15.49,
    'https://via.placeholder.com/300x200?text=Netflix+1+Month',
    'Netflix',
    -1, -- Unlimited
    true,
    'Gift code for 1 month Netflix Standard subscription. New subscribers only or can be added to existing account.'
  ),
  (
    'Movie Theater Tickets (2)',
    'Two general admission movie tickets',
    'Entertainment',
    10.00,
    24.00,
    'https://via.placeholder.com/300x200?text=Movie+Tickets',
    'AMC Theatres',
    25,
    true,
    'Valid at participating AMC Theatres. Not valid for premium formats (IMAX, Dolby, etc). Expires 90 days from redemption.'
  ),
  (
    '$25 iTunes Gift Card',
    'iTunes/App Store credit for apps, music, movies, and more',
    'Entertainment',
    12.50,
    25.00,
    'https://via.placeholder.com/300x200?text=iTunes+Gift+Card',
    'Apple',
    50,
    true,
    'Valid for purchases on iTunes, App Store, Apple Music, and Apple Books. Cannot be redeemed for cash.'
  ),
  (
    'Spotify Premium - 3 Months',
    'Three months of ad-free music streaming',
    'Entertainment',
    15.00,
    29.97,
    'https://via.placeholder.com/300x200?text=Spotify+Premium',
    'Spotify',
    -1, -- Unlimited
    true,
    'Gift code for 3 months of Spotify Premium. New subscribers only. Auto-renewal can be disabled.'
  ),

  -- Retail
  (
    '$20 Nike Store Credit',
    'Shopping credit for Nike.com or Nike stores',
    'Retail',
    10.00,
    20.00,
    'https://via.placeholder.com/300x200?text=Nike+Gift+Card',
    'Nike',
    35,
    true,
    'Valid for online and in-store purchases. Cannot be combined with other promotions.'
  ),
  (
    '$40 Walmart Gift Card',
    'Shop for anything at Walmart stores or Walmart.com',
    'Retail',
    20.00,
    40.00,
    'https://via.placeholder.com/300x200?text=Walmart+Gift+Card',
    'Walmart',
    45,
    true,
    'Redeemable at any Walmart store or on Walmart.com. Not redeemable for cash.'
  ),
  (
    '$15 Bath & Body Works Gift Card',
    'Fragrance, body care, and home products',
    'Retail',
    7.50,
    15.00,
    'https://via.placeholder.com/300x200?text=Bath+%26+Body+Works',
    'Bath & Body Works',
    30,
    true,
    'Valid at Bath & Body Works stores and online. Cannot be redeemed for cash.'
  ),

  -- Travel
  (
    '$50 Airbnb Gift Card',
    'Airbnb credit for unique stays and experiences',
    'Travel',
    25.00,
    50.00,
    'https://via.placeholder.com/300x200?text=Airbnb+Gift+Card',
    'Airbnb',
    20,
    true,
    'Credit added to Airbnb account. Valid for stays and experiences worldwide. Subject to Airbnb terms.'
  ),
  (
    '$25 Uber Gift Card',
    'Uber rides or Uber Eats credit',
    'Travel',
    12.50,
    25.00,
    'https://via.placeholder.com/300x200?text=Uber+Gift+Card',
    'Uber',
    60,
    true,
    'Credit can be used for Uber rides or Uber Eats orders. Valid in participating cities.'
  ),

  -- Services
  (
    '1-Month Gym Membership Pass',
    'One month access to participating fitness centers',
    'Services',
    20.00,
    50.00,
    'https://via.placeholder.com/300x200?text=Gym+Membership',
    'ClassPass',
    15,
    true,
    'Pass valid at participating ClassPass partner gyms. First-time users only. Membership auto-renews unless cancelled.'
  ),
  (
    '$30 Car Wash Package',
    'Five premium car washes at participating locations',
    'Services',
    15.00,
    30.00,
    'https://via.placeholder.com/300x200?text=Car+Wash',
    'EcoWash Auto Spa',
    25,
    true,
    'Package includes 5 premium washes. Valid at participating locations. Expires 6 months from redemption.'
  );

-- Add some high-value rewards for testing
INSERT INTO public.rewards (title, description, category, serv_dr_cost, retail_value, image_url, vendor_name, stock_quantity, is_active, terms_and_conditions)
VALUES
  (
    '$100 Best Buy Gift Card',
    'Electronics, appliances, and more at Best Buy',
    'Retail',
    50.00,
    100.00,
    'https://via.placeholder.com/300x200?text=Best+Buy',
    'Best Buy',
    10,
    true,
    'Valid for in-store and online purchases at Best Buy. Cannot be redeemed for cash.'
  ),
  (
    '$200 Southwest Airlines Gift Card',
    'Book flights on Southwest Airlines',
    'Travel',
    100.00,
    200.00,
    'https://via.placeholder.com/300x200?text=Southwest+Airlines',
    'Southwest Airlines',
    5,
    true,
    'Gift card valid for Southwest Airlines flight bookings. Subject to airline terms and conditions.'
  ),
  (
    'Apple AirPods (3rd Gen)',
    'Wireless earbuds with spatial audio',
    'Retail',
    85.00,
    169.00,
    'https://via.placeholder.com/300x200?text=AirPods',
    'Apple',
    3,
    true,
    'Brand new Apple AirPods (3rd Generation). Includes charging case. Ships within 5-7 business days. Limited quantity.'
  );

-- Note: These are sample rewards with placeholder images
-- In production, replace with actual product images and update stock quantities
