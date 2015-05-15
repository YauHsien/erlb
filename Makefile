.PHONY: all clean test

all:
	./rebar compile

clean:
	./rebar clean

test:
	./rebar eunit
