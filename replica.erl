%%% Heqing Huang (hh1816) Zifan Wu (zw8515) 
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(replica).
-export([start/1]).

start(Database) ->
  receive
    {bind, Leaders} -> 
       next(Leaders, [], #{}, #{}, 1, 1, Database)
  end.

next(Leaders, Requests, Decisions, Proposals, Slot_in, Slot_out, Database) ->
  receive
    {request, C} ->      % request from client
      Tmp_Requests = Requests ++ [C],
      New_Decisions = Decisions,
      Tmp_Proposals = Proposals,
      New_Slot_out = Slot_out;
    {decision, S, C} ->  % decision from commander
      New_Decisions = maps:put(S, C, Decisions),
      {Tmp_Proposals, Tmp_Requests, New_Slot_out} = decide (Proposals, Decisions, Requests, Slot_out, Database)
  end, % receive

  {New_Requests, New_Proposals, New_Slot_in} = propose(Leaders, Tmp_Requests, Tmp_Proposals, New_Decisions, Slot_in, New_Slot_out),
  next(Leaders, New_Requests, New_Decisions, New_Proposals, New_Slot_in, New_Slot_out, Database).

send(Id, Msg) ->
  Id ! Msg.

propose(Leaders, Requests, Proposals, Decisions, Slot_in, Slot_out) ->
  WINDOW = 5,
  %%%io:format("length ~p ~p ~p ~n", [(Slot_in < (Slot_out + WINDOW)), Slot_in, Slot_out ]),
  if
    (length(Requests) /= 0) and (Slot_in < (Slot_out + WINDOW)) ->
      %%%io:format("enter ~n"),
      Is_key = maps:is_key(Slot_in, Decisions), 
      if
        Is_key == false ->
          Cmd = lists:nth(1, Requests),
          New_Requests = lists:reverse(lists:droplast(lists:reverse(Requests))),
          New_Proposals = maps:put(Slot_in, Cmd, Proposals),
          %%%io:format("replica:  slot in ~p,  cmd ~p ~n", [Slot_in, Cmd]),
          [send(Leader, {propose, Slot_in, Cmd}) || Leader <- Leaders];
        true ->
          New_Requests = Requests,
          New_Proposals = Proposals
      end,
      propose(Leaders, New_Requests, New_Proposals, Decisions, Slot_in + 1, Slot_out);
    true ->
      {Requests, Proposals, Slot_in}
  end.
  
   
decide(Proposals, Decisions, Requests, Slot_out, Database) ->
  Cmd1 = maps:get(Slot_out, Decisions, naive),
  if
    Cmd1 /= naive ->
      Cmd2 = maps:get(Slot_out, Proposals, naive),
      if
        Cmd2 /= naive ->
          if
            Cmd2 /= Cmd1 ->
              New_Requests = Requests ++ [Cmd2];
            true ->
              New_Requests = Requests
          end,
          New_Proposals = maps:remove(Slot_out, Proposals);
        true ->
          New_Proposals = Proposals,
          New_Requests = Requests
      end,
      New_Slot_out = perform(Cmd1, Decisions, Slot_out, Database),
      decide(New_Proposals, Decisions, New_Requests, New_Slot_out, Database);
    true ->
      New_Proposals = Proposals,
      New_Requests = Requests,
      New_Slot_out = Slot_out
  end,
  {New_Proposals, New_Requests, New_Slot_out}.

perform(Cmd, Decisions, Slot_out, Database) ->
  {Client, Cid, Op} = Cmd,
  %%%io:format(" cmd ~p ~n", [Cmd]),
  Is_member = lists:member(Cmd, maps:values(maps:with(lists:seq(1, Slot_out - 1), Decisions))),
  if
    Is_member == true ->
      nothing;
    true ->
      Database ! {execute, Op},
      Client ! {response, Cid, ok}
  end,
  Slot_out + 1.



