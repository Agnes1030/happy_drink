create extension if not exists "pgcrypto";

alter table drink_records
  add column if not exists is_test boolean not null default false;

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  phone varchar(32) unique,
  email varchar(255) unique,
  password_hash varchar(255),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_phone_or_email_check check (phone is not null or email is not null)
);

create table if not exists drink_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  drink_type varchar(32) not null,
  brand varchar(100),
  product_name varchar(200),
  size_ml int,
  sugar_level varchar(32),
  ice_level varchar(32),
  cups int not null default 1,
  unit_price numeric(10,2),
  total_price numeric(10,2),
  caffeine_mg_est int,
  consumed_at timestamptz not null,
  note text,
  image_url text,
  source varchar(32) not null default 'manual',
  parse_confidence numeric(5,4),
  is_test boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint drink_records_drink_type_check check (drink_type in ('milk_tea', 'coffee', 'other')),
  constraint drink_records_source_check check (source in ('manual', 'photo_auto', 'photo_confirmed')),
  constraint drink_records_sugar_level_check check (
    sugar_level is null or sugar_level in ('no_sugar', 'less_sugar', 'half', 'full')
  ),
  constraint drink_records_cups_check check (cups > 0),
  constraint drink_records_size_ml_check check (size_ml is null or size_ml > 0),
  constraint drink_records_price_check check (
    (unit_price is null or unit_price >= 0) and (total_price is null or total_price >= 0)
  ),
  constraint drink_records_confidence_check check (
    parse_confidence is null or (parse_confidence >= 0 and parse_confidence <= 1)
  )
);

create index if not exists idx_drink_records_user_consumed_at
  on drink_records(user_id, consumed_at desc);

create table if not exists parse_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  image_url text not null,
  status varchar(32) not null default 'pending',
  ocr_text text,
  parsed_json jsonb,
  confidence numeric(5,4),
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint parse_jobs_status_check check (
    status in ('pending', 'processing', 'done', 'failed', 'needs_confirm')
  ),
  constraint parse_jobs_confidence_check check (
    confidence is null or (confidence >= 0 and confidence <= 1)
  )
);

create table if not exists qa_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  question text not null,
  intent varchar(32),
  time_range varchar(64),
  query_template varchar(100),
  query_params jsonb,
  answer_text text,
  created_at timestamptz not null default now(),
  constraint qa_logs_intent_check check (
    intent is null or intent in ('intake', 'spending', 'habit')
  )
);

create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_users_updated_at on users;
create trigger trg_users_updated_at
before update on users
for each row execute function set_updated_at();

drop trigger if exists trg_drink_records_updated_at on drink_records;
create trigger trg_drink_records_updated_at
before update on drink_records
for each row execute function set_updated_at();

drop trigger if exists trg_parse_jobs_updated_at on parse_jobs;
create trigger trg_parse_jobs_updated_at
before update on parse_jobs
for each row execute function set_updated_at();
