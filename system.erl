%%% Heqing Huang (hh1816) Zifan Wu (zw8515) 
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(system).
-export([start/0]).

start() ->
  %%% Not working, so wired!
  %[S , C , A, T|  _] = Input, 
  %Si = atom_to_list(S),
  %N_servers = list_to_integer(Si),
  %Ci = atom_to_list(C),
  %N_clients = list_to_integer(Ci),
  %Ai = atom_to_list(A),
  %N_accounts = list_to_integer(Ai),
  %Ti = atom_to_list(T),
  %End_after = list_to_integer(Ti),

  N_servers  = 5,
  N_clients  = 3,
  N_accounts = 10,
  Max_amount = 1000,  

  End_after  = 1000,   %  Milli-seconds for Simulation
  io:format("current N_servers: ~p, N_clients: ~p, N_accounts: ~p, Timeout: ~p ~n", [N_servers, N_clients, N_accounts, End_after]),
  _Servers = [ spawn(server, start, [self(), N_accounts, End_after]) 
    || _ <- lists:seq(1, N_servers) ],
 
  
  Components = [ receive {config, R, A, L} -> {R, A, L} end 
    || _ <- lists:seq(1, N_servers) ],

 
  {Replicas, Acceptors, Leaders} = lists:unzip3(Components),
  
  [ Replica ! {bind, Leaders} || Replica <- Replicas ],
  [ Leader  ! {bind, Acceptors, Replicas} || Leader <- Leaders ],

  _Clients = [ spawn(client, start, 
               [Replicas, N_accounts, Max_amount, End_after])
    || _ <- lists:seq(1, N_clients) ],

  done.

