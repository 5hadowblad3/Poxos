%%% Heqing Huang (hh1816) Zifan Wu (zw8515) 

-module(acceptor).
-export([start/0]).


start() ->
  Ballot_num = 0,
  Accepted = [],

  next(Ballot_num, Accepted).

next(Ballot_num, Accepted) ->
  receive
  	{p1a, ID, Bn} ->
  	  if 
  	  	Ballot_num < Bn ->
  	  	  N_Ballot_num = Bn;
  	  	true ->
  	  	  N_Ballot_num = Ballot_num
  	  end,
  	  send(ID, {p1b, self(), N_Ballot_num, Accepted}),
      next(Ballot_num, Accepted);
  	{p2a, ID, {Bn, S, C}} ->
  	  if
  			Ballot_num == Bn ->
  				New_Accepted = Accepted ++ [{Bn, S, C}];
        true ->
          New_Accepted = Accepted
  		end,
  		send(ID, {p2b, self(), Ballot_num}),
      next(Ballot_num, New_Accepted)
  end.
  

send(Id, Msg) ->
  Id ! Msg.
