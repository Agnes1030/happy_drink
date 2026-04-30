-- Seed data for quick local testing
-- Usage:
-- psql "postgresql://postgres:postgres@localhost:5432/milk_tea_app" -f seed.sql

insert into users (id, phone, email, password_hash)
values
  ('00000000-0000-0000-0000-000000000001', '13800000001', 'demo1@example.com', 'demo_hash'),
  ('00000000-0000-0000-0000-000000000002', '13800000002', 'demo2@example.com', 'demo_hash')
on conflict (id) do nothing;

insert into drink_records (
  id, user_id, drink_type, brand, product_name, size_ml, sugar_level, ice_level, cups,
  unit_price, total_price, caffeine_mg_est, consumed_at, note, source, parse_confidence, is_test
)
values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'coffee', 'Starbucks', 'Americano', 473, 'no_sugar', 'less_ice', 1, 25.00, 25.00, 180, now() - interval '1 day', 'demo_seed', 'manual', null, true),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'milk_tea', 'HeyTea', 'Cheezo Tea', 500, 'half', 'less_ice', 1, 22.00, 22.00, 80, now() - interval '2 day', 'demo_seed', 'photo_confirmed', 0.88, true),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'coffee', 'Manner', 'Latte', 350, 'less_sugar', 'normal', 1, 20.00, 20.00, 140, now() - interval '3 day', 'demo_seed', 'manual', null, true),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'milk_tea', 'Nayuki', 'Fruit Tea', 500, 'full', 'normal', 1, 19.00, 19.00, 50, now() - interval '4 day', 'demo_seed', 'manual', null, true),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'coffee', 'Luckin', 'SOE', 355, 'no_sugar', 'normal', 2, 18.00, 36.00, 220, now() - interval '5 day', 'demo_seed', 'photo_auto', 0.94, true),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'milk_tea', 'CoCo', 'Pearl Milk Tea', 600, 'half', 'normal', 1, 16.00, 16.00, 65, now() - interval '6 day', 'demo_seed', 'manual', null, true),
  ('10000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 'coffee', 'Starbucks', 'Cold Brew', 473, 'no_sugar', 'normal', 1, 28.00, 28.00, 200, now() - interval '7 day', 'demo_seed', 'manual', null, true),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', 'milk_tea', 'HeyTea', 'Grape Boom', 500, 'less_sugar', 'normal', 1, 24.00, 24.00, 45, now() - interval '8 day', 'demo_seed', 'manual', null, true),
  ('10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000001', 'coffee', 'Manner', 'Flat White', 300, 'no_sugar', 'normal', 1, 22.00, 22.00, 150, now() - interval '9 day', 'demo_seed', 'manual', null, true),
  ('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'milk_tea', 'Nayuki', 'Jasmine Tea', 500, 'half', 'less_ice', 1, 18.00, 18.00, 35, now() - interval '10 day', 'demo_seed', 'manual', null, true),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001', 'coffee', 'Luckin', 'Coconut Latte', 355, 'less_sugar', 'normal', 1, 17.00, 17.00, 130, now() - interval '11 day', 'demo_seed', 'photo_confirmed', 0.91, true),
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', 'milk_tea', 'CoCo', 'Lemon Tea', 500, 'full', 'normal', 1, 14.00, 14.00, 30, now() - interval '12 day', 'demo_seed', 'manual', null, true),
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'coffee', 'Starbucks', 'Latte', 355, 'no_sugar', 'normal', 1, 29.00, 29.00, 160, now() - interval '2 day', 'demo_seed', 'manual', null, true),
  ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'milk_tea', 'HeyTea', 'Mango Tea', 500, 'half', 'normal', 1, 23.00, 23.00, 40, now() - interval '4 day', 'demo_seed', 'manual', null, true),
  ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 'coffee', 'Manner', 'Americano', 350, 'no_sugar', 'normal', 1, 19.00, 19.00, 170, now() - interval '6 day', 'demo_seed', 'manual', null, true),
  ('20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002', 'milk_tea', 'Nayuki', 'Orange Tea', 500, 'less_sugar', 'normal', 1, 20.00, 20.00, 35, now() - interval '8 day', 'demo_seed', 'manual', null, true),
  ('20000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 'coffee', 'Luckin', 'SOE', 355, 'no_sugar', 'normal', 1, 18.00, 18.00, 210, now() - interval '10 day', 'demo_seed', 'manual', null, true),
  ('20000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000002', 'milk_tea', 'CoCo', 'Milk Tea', 600, 'full', 'normal', 1, 15.00, 15.00, 60, now() - interval '12 day', 'demo_seed', 'manual', null, true),
  ('20000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000002', 'coffee', 'Starbucks', 'Cold Brew', 473, 'no_sugar', 'normal', 1, 27.00, 27.00, 190, now() - interval '14 day', 'demo_seed', 'manual', null, true),
  ('20000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000002', 'milk_tea', 'HeyTea', 'Cheese Tea', 500, 'half', 'less_ice', 1, 25.00, 25.00, 55, now() - interval '16 day', 'demo_seed', 'manual', null, true)
on conflict (id) do nothing;
