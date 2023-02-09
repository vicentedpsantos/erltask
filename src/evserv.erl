-module(evserv).

-record(state, {events,    %% list of #event{} records
                clients}). %% list of Pids

-record(event, {name="",
                description="",
                pid,
                timeout={{1970,1,1},{0,0,0}}).

init() ->
  %% Loading events from a static file could be done here.
  %% You would need to pass an argument to init telling where the
  %% resource to find the events is. Then load it from here.
  %% Another option is to just pass the events straight to the server
  %% through this function.
  loop(#state{events=orddict:new(),
              clients=orddict:new()}).

loop(S = #state{}) ->
  receive
    {Pid, MsgRef, {subscribe, Client}} ->
      Ref = erlang:monitor(process, Client),
      NewClients = orddict:store(Ref, Client, S#state.clients),
      Pid ! {MsgRef, ok},
      loop(S#state{clients=NewClients});

    {Pid, MsgRef, {add, Name, Description, TimeOut}} ->
      case valid_datetime(TimeOut) of
        true ->
          EventPid = event:start_link(Name, TimeOut),
          NewEvents = orddict:store(Name,
                                    #event{name=Name,
                                           description=Description,
                                           pid=EventPid,
                                           timeout=TimeOut},
                                    S#state.events),
          Pid ! {MsgRef, ok},
          loop(S#state{events=NewEvents});
        false ->
          Pid ! {MsgRef, {error, bad_timeout}},
          loop(S)
      end;

    {Pid, MsgRef, {cancel, Name}} ->
      Events = case orddict:find(Name, S#state.events) of
                 {ok, E} ->
                   event:cancel(E#event.pid),
                   orddict:erase(Name, S#state.events);
                 error ->
                   S#state.events
               end,
      Pid ! {MsgRef, ok},
      loop(S#state{events=Events});
  end.

valid_datetime({Date,Time}) ->
  try
    calendar:valid_date(Date) andalso valid_time(Time)
  catch
    error:function_clause -> %% not in {{Y,M,D}, {H, Min, S}}
      false
  end;
valid_datetime(_) ->
  false.

valid_time({H, M, S}) -> valid_time(H, M, S).
valid_time(H, M, S) when H >= 0, H < 24,
                         M >= 0, M < 60,
                         S >= 0, S < 60 -> true;
valid_time(_, _, _) -> false.
