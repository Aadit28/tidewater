-- New implementation, 2026-10-20. Only tw26_* objects and a new private bucket.
begin;
create table public.tw26_workspaces (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null unique references auth.users(id),
 created_at timestamptz not null default now()
);
create table public.tw26_pods (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.tw26_workspaces(id),
 name text not null, focus text not null, members integer not null check(members>0), equipment text[] not null,
 categories text[] not null, sample boolean not null default true
);
create table public.tw26_reports (
 id uuid primary key, workspace_id uuid not null references public.tw26_workspaces(id),
 title text not null check(char_length(title) between 5 and 100),
 description text not null check(char_length(description) between 15 and 1500),
 category text not null check(category in ('Marine debris','Flooding','Erosion','Access hazard')),
 urgency text not null check(urgency in ('Low','Medium','High')),
 place text not null check(char_length(place) between 3 and 100),
 lat double precision not null check(lat between -85 and 85),
 lng double precision not null check(lng between -180 and 180),
 photo_path text, sample boolean not null default false, created_at timestamptz not null default now()
);
create table public.tw26_tasks (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.tw26_workspaces(id),
 report_id uuid not null unique references public.tw26_reports(id), pod_id uuid references public.tw26_pods(id),
 status text not null default 'open' check(status in ('open','claimed','in_progress','completed')),
 assignee_id uuid references auth.users(id), version integer not null default 1,
 completion_note text, updated_at timestamptz not null default now(),
 check(status='open' or assignee_id is not null), check(status<>'completed' or char_length(completion_note)>=10)
);
create table public.tw26_events (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.tw26_workspaces(id),
 kind text not null, message text not null, report_id uuid references public.tw26_reports(id),
 created_at timestamptz not null default now()
);
create table public.tw26_commands (
 workspace_id uuid not null references public.tw26_workspaces(id), key uuid not null,
 operation text not null, payload jsonb not null, response jsonb not null,
 created_at timestamptz not null default now(), primary key(workspace_id,key)
);
create table public.tw26_outbox (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.tw26_workspaces(id),
 event_id uuid not null unique references public.tw26_events(id),
 delivery_state text not null default 'demo_only' check(delivery_state='demo_only'),
 created_at timestamptz not null default now()
);
create index on public.tw26_reports(workspace_id,created_at desc);
create index on public.tw26_tasks(workspace_id,status);
create index on public.tw26_pods(workspace_id);
create index on public.tw26_events(workspace_id,created_at desc);
alter table public.tw26_workspaces enable row level security;
alter table public.tw26_pods enable row level security;
alter table public.tw26_reports enable row level security;
alter table public.tw26_tasks enable row level security;
alter table public.tw26_events enable row level security;
alter table public.tw26_commands enable row level security;
alter table public.tw26_outbox enable row level security;
create policy tw26_workspace_read on public.tw26_workspaces for select to authenticated using(owner_id=(select auth.uid()));
create policy tw26_pod_read on public.tw26_pods for select to authenticated using(workspace_id in(select id from public.tw26_workspaces));
create policy tw26_report_read on public.tw26_reports for select to authenticated using(workspace_id in(select id from public.tw26_workspaces));
create policy tw26_task_read on public.tw26_tasks for select to authenticated using(workspace_id in(select id from public.tw26_workspaces));
create policy tw26_event_read on public.tw26_events for select to authenticated using(workspace_id in(select id from public.tw26_workspaces));
-- Commands/outbox are internal only; no client policies or grants.
revoke all on public.tw26_workspaces,public.tw26_pods,public.tw26_reports,public.tw26_tasks,public.tw26_events,public.tw26_commands,public.tw26_outbox from anon,authenticated;
grant select on public.tw26_workspaces,public.tw26_pods,public.tw26_reports,public.tw26_tasks,public.tw26_events to authenticated;

create function public.tw26_bootstrap() returns uuid language plpgsql security definer set search_path='' as $$
declare w uuid; p uuid; r uuid; i integer; titles text[]:=array['Fishing line along the shoreline','Water covering the trail approach','Dune edge needs a closer look','Debris beside the public boardwalk','Litter at the beach access','Loose boards near the landing'];
 places text[]:=array['North shore access','Marsh walk','East dune overlook','Village boardwalk','South beach path','Community landing'];
 cats text[]:=array['Marine debris','Flooding','Erosion','Marine debris','Marine debris','Access hazard'];
 lats double precision[]:=array[31.439,31.424,31.419,31.410,31.396,31.416];
 lngs double precision[]:=array[-81.259,-81.280,-81.250,-81.272,-81.267,-81.295];
begin
 if auth.uid() is null then raise exception 'Sign in to open a workspace'; end if;
 insert into public.tw26_workspaces(owner_id) values(auth.uid()) on conflict(owner_id) do nothing returning id into w;
 if w is null then select id into w from public.tw26_workspaces where owner_id=auth.uid(); return w; end if;
 insert into public.tw26_pods(workspace_id,name,focus,members,equipment,categories) values
 (w,'Shoreline Stewards','Small debris and beach access',4,array['Gloves','Litter pickers','Collection bags'],array['Marine debris']),
 (w,'Trail & Access Team','Walkways and access observations',3,array['Hand tools','Safety markers'],array['Access hazard','Marine debris']),
 (w,'Coast Watch','Document water and dune changes',5,array['Measuring tape','Camera','Field notebook'],array['Flooding','Erosion']);
 for i in 1..6 loop
  r:=gen_random_uuid();
  insert into public.tw26_reports(id,workspace_id,title,description,category,urgency,place,lat,lng,sample,created_at)
  values(r,w,titles[i],'Synthetic example for this private demo. Observe from a safe public location; never enter water or handle hazardous material.',cats[i],case when i in(2,6) then 'High' when i=5 then 'Low' else 'Medium' end,places[i],lats[i],lngs[i],true,now()-(i||' hours')::interval);
  select id into p from public.tw26_pods where workspace_id=w and cats[i]=any(categories) order by name limit 1;
  insert into public.tw26_tasks(workspace_id,report_id,pod_id,status,assignee_id,completion_note)
  values(w,r,p,case when i=5 then 'completed' else 'open' end,case when i=5 then auth.uid() else null end,case when i=5 then 'Synthetic completion for demonstration only.' else null end);
 end loop;
 insert into public.tw26_events(workspace_id,kind,message) values(w,'workspace.created','Your private demo workspace was created with six synthetic reports and three sample teams.');
 return w;
end $$;

create function public.tw26_create_report(p_key uuid,p_id uuid,p_payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare w uuid; prior public.tw26_commands; response jsonb; e uuid; path text; payload jsonb;
begin
 select id into w from public.tw26_workspaces where owner_id=auth.uid();
 if w is null then raise exception 'Open a signed-in workspace first'; end if;
 perform pg_advisory_xact_lock(hashtextextended(w::text,26));
 payload:=jsonb_build_object('id',p_id,'data',p_payload);
 select * into prior from public.tw26_commands where workspace_id=w and key=p_key;
 if found then
  if prior.operation<>'report.create' or prior.payload<>payload then raise exception 'This request key was already used for different content'; end if;
  return prior.response;
 end if;
 if (select count(*) from public.tw26_reports where workspace_id=w)>=200 then raise exception 'Demo workspace limit reached'; end if;
 path:=nullif(p_payload->>'photo_path','');
 if path is not null and (path<>auth.uid()::text||'/'||p_id::text||'.jpg' or not exists(select 1 from storage.objects where bucket_id='tw26-private-photos' and name=path)) then raise exception 'Photo does not belong to this report'; end if;
 insert into public.tw26_reports(id,workspace_id,title,description,category,urgency,place,lat,lng,photo_path)
 values(p_id,w,btrim(p_payload->>'title'),btrim(p_payload->>'description'),p_payload->>'category',p_payload->>'urgency',btrim(p_payload->>'place'),(p_payload->>'lat')::double precision,(p_payload->>'lng')::double precision,path);
 insert into public.tw26_tasks(workspace_id,report_id) values(w,p_id);
 insert into public.tw26_events(workspace_id,kind,message,report_id) values(w,'report.created','New report: '||btrim(p_payload->>'title'),p_id) returning id into e;
 insert into public.tw26_outbox(workspace_id,event_id) values(w,e);
 response:=jsonb_build_object('report_id',p_id);
 insert into public.tw26_commands(workspace_id,key,operation,payload,response) values(w,p_key,'report.create',payload,response);
 return response;
end $$;

create function public.tw26_task_command(p_key uuid,p_task uuid,p_version integer,p_action text,p_note text default '',p_pod uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare w uuid; t public.tw26_tasks; prior public.tw26_commands; payload jsonb; response jsonb; e uuid; next_status text;
begin
 select id into w from public.tw26_workspaces where owner_id=auth.uid();
 if w is null then raise exception 'Sign in before changing a task'; end if;
 perform pg_advisory_xact_lock(hashtextextended(w::text,26));
 payload:=jsonb_build_object('task',p_task,'version',p_version,'action',p_action,'note',p_note,'pod',p_pod);
 select * into prior from public.tw26_commands where workspace_id=w and key=p_key;
 if found then
  if prior.operation<>'task.change' or prior.payload<>payload then raise exception 'This request key was already used for different content'; end if;
  return prior.response;
 end if;
 select * into t from public.tw26_tasks where id=p_task and workspace_id=w for update;
 if not found then raise exception 'Task not found in your workspace'; end if;
 if t.version<>p_version then raise exception 'Task changed. Refresh and try again.'; end if;
 next_status:=t.status;
 if p_action='assign' then
  if t.status='completed' then raise exception 'Completed tasks cannot be reassigned'; end if;
  if not exists(select 1 from public.tw26_pods p join public.tw26_reports r on r.id=t.report_id where p.id=p_pod and p.workspace_id=w and r.category=any(p.categories)) then raise exception 'Choose a team with a matching focus'; end if;
 elsif p_action='claim' and t.status='open' then next_status:='claimed';
 elsif p_action='start' and t.status='claimed' and t.assignee_id=auth.uid() then next_status:='in_progress';
 elsif p_action='release' and t.status='claimed' and t.assignee_id=auth.uid() then next_status:='open';
 elsif p_action='complete' and t.status='in_progress' and t.assignee_id=auth.uid() then
  if char_length(btrim(coalesce(p_note,''))) not between 10 and 1000 then raise exception 'Add a completion note of 10–1000 characters'; end if;
  next_status:='completed';
 else raise exception 'That task transition is not available'; end if;
 update public.tw26_tasks set status=next_status,version=version+1,updated_at=now(),
  assignee_id=case when p_action='claim' then auth.uid() when p_action='release' then null else assignee_id end,
  pod_id=case when p_action='assign' then p_pod else pod_id end,
  completion_note=case when p_action='complete' then btrim(p_note) else completion_note end
 where id=t.id;
 insert into public.tw26_events(workspace_id,kind,message,report_id)
 values(w,'task.'||p_action,case p_action when 'assign' then 'Team assigned' when 'claim' then 'Task claimed by you' when 'start' then 'Task started' when 'release' then 'Task returned to the open queue' else 'Task marked complete by you' end,t.report_id) returning id into e;
 insert into public.tw26_outbox(workspace_id,event_id) values(w,e);
 response:=jsonb_build_object('task_id',t.id,'version',t.version+1,'status',next_status);
 insert into public.tw26_commands(workspace_id,key,operation,payload,response) values(w,p_key,'task.change',payload,response);
 return response;
end $$;

revoke all on function public.tw26_bootstrap(),public.tw26_create_report(uuid,uuid,jsonb),public.tw26_task_command(uuid,uuid,integer,text,text,uuid) from public,anon;
grant execute on function public.tw26_bootstrap(),public.tw26_create_report(uuid,uuid,jsonb),public.tw26_task_command(uuid,uuid,integer,text,text,uuid) to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('tw26-private-photos','tw26-private-photos',false,5242880,array['image/jpeg']);
create policy tw26_photo_insert on storage.objects for insert to authenticated with check(bucket_id='tw26-private-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy tw26_photo_read on storage.objects for select to authenticated using(bucket_id='tw26-private-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);
commit;
