%%% Heqing Huang (hh1816) Zifan Wu (zw8515) 

-module(scout).
-export([start/3]).

start(Leader, Acceptors, Ballot_num) ->
  Waitfor = Acceptors,
  Pvalue = [],
  %%%Msg =  {p1a, self(), Ballot_num},
  [Acceptor ! {p1a, self(), Ballot_num} || Acceptor <- Acceptors],

  next(Leader, Waitfor, Ballot_num, Pvalue, Acceptors).

next(Leader, Waitfor, Ballot_num, Pvalue, Acceptors) ->
  receive
	{p1b, ID, Bn, Msg} ->
	  if
	    Ballot_num == Bn ->
	      %%%io:format("scout before: pval ~p ~n ", [Pvalue]),
		  New_Pvalue = Pvalue ++ Msg,
		  %%%io:format("scout after: pval ~p ~n ", [New_Pvalue]),
		  New_Waitfor = lists:delete(ID, Waitfor),
			if
              length(New_Waitfor) < length(Acceptors) / 2 ->
				send(Leader, {adopted, Bn, New_Pvalue});
              true ->
				next(Leader, New_Waitfor, Ballot_num, New_Pvalue, Acceptors)
			end;
        true ->
		  New_Pvalue = Pvalue,
		  New_Waitfor = Waitfor,
		  send(Leader, {preempted, Bn})
	  end
  end,
  next(Leader, New_Waitfor, Ballot_num, New_Pvalue, Acceptors).

send(Id, Msg) ->
  Id ! Msg.