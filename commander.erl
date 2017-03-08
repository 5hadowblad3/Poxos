%%% Heqing Huang (hh1816) Zifan Wu (zw8515) 

-module(commander).
-export([start/4]).

start(Leader, Acceptors, Replicas, {Bn, S, Cmd}) ->
  Waitfor = Acceptors,
  [send(Acceptor, {p2a, self(), {Bn, S, Cmd}}) || Acceptor <- Acceptors],

  next(Leader, Acceptors, Replicas, {Bn, S, Cmd}, Waitfor).

next(Leader, Acceptors, Replicas, {Bn, S, Cmd}, Waitfor) ->
  receive
    {p2b, ID, Ballot_num} ->
	  if
	    Bn == Ballot_num ->
		  New_Waitfor = lists:delete(ID, Waitfor),
          if
            length(New_Waitfor) < length(Acceptors) / 2 ->
              [send(Replica, {decision, S, Cmd}) || Replica <- Replicas];
            true ->
              next(Leader, Acceptors, Replicas, {Bn, S, Cmd}, New_Waitfor)
          end;
        true ->
          send(Leader, {preempted, Bn})
      end
  end.

send(Id, Msg) ->
  Id ! Msg.