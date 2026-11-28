-- Reuse the existing private claim-documents bucket.
-- Never create a second motor-specific bucket.
-- Firebase ID tokens are verified by Supabase Third-Party Auth.
-- Firebase tokens without a custom role claim use the anon Postgres role.

begin;

do $$
begin
  if not exists (
    select 1 from storage.buckets where id = 'claim-documents'
  ) then
    raise exception 'The existing claim-documents bucket was not found. No bucket was created.';
  end if;

  if exists (
    select 1 from storage.objects where bucket_id = 'motor-claim-documents'
  ) then
    raise exception 'The extra motor-claim-documents bucket is not empty. Refusing to remove it.';
  end if;
end;
$$;

-- Keep the original bucket private and apply the limits expected by the app.
update storage.buckets
set
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
where id = 'claim-documents';

-- Remove the policies that were first created for the duplicate bucket.
drop policy if exists "Only Insure-Plus Firebase tokens can access motor claim files"
  on storage.objects;
drop policy if exists "Claim owners can read their private claim files"
  on storage.objects;
drop policy if exists "Claim owners can upload their private claim files"
  on storage.objects;
drop policy if exists "Claim owners can delete their private claim files"
  on storage.objects;

-- Reject unverified/non-Insure-Plus Firebase tokens for this bucket only.
create policy "Only Insure-Plus Firebase tokens can access claim files"
on storage.objects as restrictive for all to anon, authenticated
using (
  bucket_id <> 'claim-documents'
  or (select public.is_insure_plus_firebase_token())
)
with check (
  bucket_id <> 'claim-documents'
  or (select public.is_insure_plus_firebase_token())
);

-- Object layout: <firebase_uid>/<claim_id>/<document_type>/<file>.
create policy "Claim owners can read their private claim files"
on storage.objects for select to anon, authenticated
using (
  bucket_id = 'claim-documents'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
);

create policy "Claim owners can upload their private claim files"
on storage.objects for insert to anon, authenticated
with check (
  bucket_id = 'claim-documents'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
  and (storage.foldername(name))[2] is not null
  and (storage.foldername(name))[3] in ('AccidentPhoto','SupportingDocument')
);

create policy "Claim owners can delete their private claim files"
on storage.objects for delete to anon, authenticated
using (
  bucket_id = 'claim-documents'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
);

-- Supabase blocks direct SQL deletion of Storage buckets.
-- The empty accidental motor-claim-documents bucket must be removed
-- through Storage > Files in the Supabase Dashboard after this migration.
commit;
