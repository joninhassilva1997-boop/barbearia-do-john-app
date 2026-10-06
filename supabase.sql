-- Banco de dados da Barbearia do John
create extension if not exists btree_gist;

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  service text not null,
  booking_date date not null,
  start_time time not null,
  end_time time not null,
  reference text,
  notes text,
  status text not null default 'pending' check (status in ('pending','confirmed','cancelled','completed')),
  created_at timestamptz not null default now()
);

alter table public.bookings enable row level security;

-- Clientes podem criar pedidos. Não podem listar os pedidos de outras pessoas.
create policy "public can create booking"
on public.bookings for insert
to anon, authenticated
with check (status = 'pending');

-- O painel usa Auth e só o usuário autenticado pode consultar/alterar pedidos.
create policy "authenticated can view bookings"
on public.bookings for select
to authenticated
using (true);

create policy "authenticated can update bookings"
on public.bookings for update
to authenticated
using (true)
with check (true);

create policy "authenticated can delete bookings"
on public.bookings for delete
to authenticated
using (true);

-- Impede dois agendamentos com o mesmo intervalo.
alter table public.bookings
  add constraint bookings_no_overlap
  exclude using gist (
    booking_date with =,
    tsrange(
      (booking_date + start_time),
      (booking_date + end_time),
      '[)'
    ) with &&
  )
  where (status in ('pending','confirmed'));

create index if not exists bookings_date_idx on public.bookings(booking_date, start_time);
