-- Insure-Plus Motor Claims: Supabase PostgreSQL and private Storage
-- Firebase is the external identity provider. Configure Firebase in
-- Supabase > Authentication > Third-Party Auth before using the client.
--
-- Firebase ID tokens without a custom "role" claim run as Supabase "anon".
-- These policies explicitly allow anon + authenticated roles but require the
-- verified Insure-Plus Firebase issuer, audience and Firebase UID (sub).

create or replace function public.is_insure_plus_firebase_token()
returns boolean
language sql
stable
as $$
  select coalesce(
    auth.jwt() ->> 'iss' = 'https://securetoken.google.com/insure-plus'
    and auth.jwt() ->> 'aud' = 'insure-plus',
    false
  );
$$;

create table if not exists public.claims (
  claim_id text primary key,
  user_id text not null,
  policy_id text not null,
  claim_type text not null default 'Motor Claim',
  claim_amount numeric(14,2) not null default 0 check (claim_amount >= 0),
  description text not null default '',
  status text not null default 'Submitted'
    check (status in ('Submitted','UnderReview','MoreInfoRequired','Approved','Rejected')),
  documents jsonb not null default '[]'::jsonb
    check (jsonb_typeof(documents) = 'array'),
  created_at timestamptz not null default now(),
  claimant_name text not null default '',
  contact_number text not null default '',
  vehicle_registration_number text not null default '',
  vehicle_make text not null default '',
  vehicle_model text not null default '',
  vehicle_year integer not null default 0,
  vehicle_type text not null default 'Car',
  incident_date date not null default current_date,
  incident_time text not null default '',
  incident_location text not null default '',
  incident_type text not null default 'Collision',
  damage_severity text not null default 'Moderate',
  is_vehicle_drivable boolean not null default true,
  police_report_filed boolean not null default false,
  police_report_number text,
  driver_name text not null default '',
  driver_license_number text not null default '',
  relationship_to_insured text not null default 'Self',
  third_party_involved boolean not null default false,
  third_party_name text,
  third_party_vehicle_number text,
  third_party_contact text,
  third_party_insurance text,
  notes text,
  approved_amount numeric(14,2)
);

create index if not exists claims_user_created_idx
  on public.claims (user_id, created_at desc);
create index if not exists claims_policy_idx on public.claims (policy_id);

alter table public.claims enable row level security;
grant select, insert, update, delete on public.claims to anon, authenticated;

drop policy if exists "Only Insure-Plus Firebase tokens can access claims" on public.claims;
create policy "Only Insure-Plus Firebase tokens can access claims"
on public.claims as restrictive for all to anon, authenticated
using ((select public.is_insure_plus_firebase_token()))
with check ((select public.is_insure_plus_firebase_token()));

drop policy if exists "Claim owners and admins can read claims" on public.claims;
create policy "Claim owners and admins can read claims"
on public.claims for select to anon, authenticated
using (
  user_id = (select auth.jwt() ->> 'sub')
  or coalesce((select auth.jwt() ->> 'admin') = 'true', false)
);

drop policy if exists "Users can submit their own claims" on public.claims;
create policy "Users can submit their own claims"
on public.claims for insert to anon, authenticated
with check (
  user_id = (select auth.jwt() ->> 'sub')
  and status = 'Submitted'
);

drop policy if exists "Owners can edit details and admins can manage claims" on public.claims;
create policy "Owners can edit details and admins can manage claims"
on public.claims for update to anon, authenticated
using (
  user_id = (select auth.jwt() ->> 'sub')
  or coalesce((select auth.jwt() ->> 'admin') = 'true', false)
)
with check (
  user_id = (select auth.jwt() ->> 'sub')
  or coalesce((select auth.jwt() ->> 'admin') = 'true', false)
);

drop policy if exists "Owners can withdraw submitted claims and admins can delete" on public.claims;
create policy "Owners can withdraw submitted claims and admins can delete"
on public.claims for delete to anon, authenticated
using (
  (user_id = (select auth.jwt() ->> 'sub') and status = 'Submitted')
  or coalesce((select auth.jwt() ->> 'admin') = 'true', false)
);

-- Claim owners may edit details, not identity, lifecycle or settlement fields.
-- Trusted Firebase custom claim admin:true is issued only by a server.
create or replace function public.protect_motor_claim_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce((auth.jwt() ->> 'admin') = 'true', false) then
    return new;
  end if;

  if new.claim_id is distinct from old.claim_id
    or new.user_id is distinct from old.user_id
    or new.claim_type is distinct from old.claim_type
    or new.created_at is distinct from old.created_at
    or new.status is distinct from old.status
    or new.approved_amount is distinct from old.approved_amount then
    raise exception 'Protected claim fields can only be changed by an administrator'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists protect_motor_claim_fields on public.claims;
create trigger protect_motor_claim_fields
before update on public.claims
for each row execute function public.protect_motor_claim_fields();

grant select, insert, delete on storage.objects to anon, authenticated;

-- Reuse the existing claim-documents bucket only; never create another bucket.
do $$
begin
  if not exists (
    select 1 from storage.buckets where id = 'claim-documents'
  ) then
    raise exception 'The existing claim-documents bucket is required. No bucket was created.';
  end if;
end;
$$;

drop policy if exists "Only Insure-Plus Firebase tokens can access motor claim files" on storage.objects;
create policy "Only Insure-Plus Firebase tokens can access motor claim files"
on storage.objects as restrictive for all to anon, authenticated
using (
  bucket_id <> 'claim-documents'
  or (select public.is_insure_plus_firebase_token())
)
with check (
  bucket_id <> 'claim-documents'
  or (select public.is_insure_plus_firebase_token())
);

drop policy if exists "Claim owners can read their private claim files" on storage.objects;
create policy "Claim owners can read their private claim files"
on storage.objects for select to anon, authenticated
using (
  bucket_id = 'claim-documents'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
);

drop policy if exists "Claim owners can upload their private claim files" on storage.objects;
create policy "Claim owners can upload their private claim files"
on storage.objects for insert to anon, authenticated
with check (
  bucket_id = 'claim-documents'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
  and (storage.foldername(name))[2] is not null
  and (storage.foldername(name))[3] in ('AccidentPhoto','SupportingDocument')
);

drop policy if exists "Claim owners can delete their private claim files" on storage.objects;
create policy "Claim owners can delete their private claim files"
on storage.objects for delete to anon, authenticated
using (
  bucket_id = 'claim-documents'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
);
