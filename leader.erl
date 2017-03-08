%%% Heqing Huang (hh1816) Zifan Wu (zw8515) 

-module(leader).
-export([start/0]).

start() ->
  receive
    {bind, Acceptors, Replicas} ->
      Ballot_num = 0,
      Active = false,
      Proposals = #{},
      spawn(scout, start, [self(), Acceptors, Ballot_num]),
      next(self(), Acceptors, Replicas, Ballot_num, Active, Proposals)
  end.

next(ID, Acceptors, Replicas, Ballot_num, Active, Proposals) ->
  receive
  	{propose, Src, Cmd} ->
      Is_key = maps:is_key(Src, Proposals),
  	  if
  	  	Is_key == false ->
  	  	  New_Proposals = maps:put(Src, Cmd, Proposals),
          if 
          	Active ->
  	  	      spawn(commander, start, [ID, Acceptors, Replicas, {Ballot_num, Src, Cmd}]);
  	  	    true ->
  	  	      nothing
  	  	  end;
  	  	true ->
  	  	  New_Proposals = Proposals
  	  end,
  	  next(ID, Acceptors, Replicas, Ballot_num, Active, New_Proposals);
  	{adopted, Bn, Pval} ->
  	  if
  	    Bn == Ballot_num ->
  	      %%%Max_Value = pmax(Pval, []),
  	  	  New_Proposals = update(Pval, Proposals, #{}),
          Key_set = maps:keys(Proposals),
  	  	  [spawn(commander, start, [ID, Acceptors, Replicas, {Bn, Src, maps:get(Src, Proposals)}]) || Src <- Key_set],
  	  	  New_Active = true;
        true ->
          New_Proposals = Proposals,
          New_Active = Active
  	  end,
  	  next(ID, Acceptors, Replicas, Ballot_num, New_Active, New_Proposals);
  	{preempted, Bn} ->
  	  if
  	  	Bn > Ballot_num ->
  	  	  New_Active = false,
  	  	  New_Ballot_num = Bn + 1,
  	  	  spawn(scout, start, [ID, Acceptors, New_Ballot_num]);
        true ->
          New_Active = Active,
          New_Ballot_num = Ballot_num
  	  end,
  	  next(ID, Acceptors, Replicas, New_Ballot_num, New_Active, Proposals)
  end.

  
update([], Proposals, _) -> Proposals;
update([H | T], Proposals, Pmax) when tuple_size(H) > 0 ->
  %%%io:format("lalala H ~p~n", [H]),
  Bn = element(1, H),
  Src = element(2, H),
  Cmd = element(3, H),
  Value = maps:get(Src, Pmax, false),
  if
    Value == false ->
      New_Pmax = maps:put(Src, Bn, Pmax),
      New_Proposals = maps:update(Src, Cmd, Proposals);
    Value < Bn ->
      New_Pmax = maps:update(Src, Bn, Pmax),
      New_Proposals = maps:update(Src, Cmd, Proposals);
    true ->
      New_Pmax = Pmax,
      New_Proposals = Proposals
  end,
  update(T, New_Proposals, New_Pmax).






      