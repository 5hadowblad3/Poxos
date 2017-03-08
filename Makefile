

.SUFFIXES: .erl .beam

MODULES  = acceptor client commander database leader replica scout server system
HOSTS    = 3
HOSTSm1  = 2

# BUILD =======================================================

ERLC	= erlc -o ebin

ebin/%.beam: %.erl
	$(ERLC) $<

all:	ebin ${MODULES:%=ebin/%.beam} 

ebin:	
	mkdir ebin

debug:
	erl -s crashdump_viewer start 

.PHONY: clean
clean:
	rm -f ebin/* erl_crash.dump

# LOCAL RUN ===================================================
SYSTEM     = system
SYSTEM1    = system1
SYSTEM2    = system2
SYSTEM3    = system3
SYSTEM4    = system4
SYSTEM5    = system5
SYSTEM6    = system6

L_SYSTEM  = system2

L_HOST    = localhost.localdomain
L_ERL     = erl -noshell -pa ebin -setcookie pass
L_ERLNODE = node

run:    all
	$(L_ERL) -s $(SYSTEM) start

# DOCKER RUN ===================================================

D_SYSTEM   = system3

D_SUBNET   = 172.19.0
D_HOSTNAME = host
D_HOST_DIR = /code
D_ERL      = erl -noshell -pa $(D_HOST_DIR)/ebin -setcookie pass
D_ERLNODE  = node

run4:	
	for k in $$(seq 1 1 $(HOSTSm1)); do \
	  docker exec -itd $(D_HOSTNAME)$$k \
	     $(D_ERL) -name $(D_ERLNODE)@$(D_SUBNET).$$k ; \
	done

	docker exec -it $(D_HOSTNAME)$(HOSTS) \
	  $(D_ERL) -name $(D_ERLNODE)@$(D_SUBNET).3 -s $(D_SYSTEM) start 

