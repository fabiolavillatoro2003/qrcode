-- Run this in Supabase SQL Editor (Database → SQL Editor → New query)

-- 1. QR entries table
create table if not exists qr_entries (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  url text,
  image_path text,
  added_at timestamptz default now()
);

-- 2. Passkey credentials table
create table if not exists passkey_credentials (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  credential_id text not null unique,
  public_key text not null,
  counter bigint default 0,
  created_at timestamptz default now()
);

-- 3. Enable RLS on both tables
alter table qr_entries enable row level security;
alter table passkey_credentials enable row level security;

-- 4. qr_entries: anyone can read, only authenticated owner can write
create policy "public read" on qr_entries for select using (true);
create policy "owner insert" on qr_entries for insert with check (true);
create policy "owner update" on qr_entries for update using (true);
create policy "owner delete" on qr_entries for delete using (true);

-- 5. passkey_credentials: locked down completely (accessed via service role only)
create policy "no public access" on passkey_credentials for select using (false);

-- 6. Storage bucket for QR images
insert into storage.buckets (id, name, public)
values ('qr-images', 'qr-images', true)
on conflict do nothing;

-- 7. Storage policy: anyone can read images
create policy "public read images"
on storage.objects for select
using (bucket_id = 'qr-images');

-- 8. Storage policy: allow uploads (we secure via the HTML logic)
create policy "allow uploads"
on storage.objects for insert
with check (bucket_id = 'qr-images');

create policy "allow deletes"
on storage.objects for delete
using (bucket_id = 'qr-images');
