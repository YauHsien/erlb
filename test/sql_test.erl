-module(sql_test).
-include_lib("eunit/include/eunit.hrl").

escape_char_test() ->
    ?assertMatch("\\0", sql:escape_char($\0) ),
    ?assertMatch("\\b", sql:escape_char($\b) ),
    ?assertMatch("\\t", sql:escape_char($\t) ),
    ?assertMatch("\\n", sql:escape_char($\n) ),
    ?assertMatch("\\r", sql:escape_char($\r) ),
    ?assertMatch("\\z", sql:escape_char($\z) ),
    ?assertMatch("\\\"", sql:escape_char($\") ),
    ?assertMatch("\\%", sql:escape_char($\x{25}) ),
    ?assertMatch("\\'", sql:escape_char($\') ),
    ?assertMatch("\\\\", sql:escape_char($\\) ),
    ?assertMatch("\\_", sql:escape_char($\_) ),
    ?assertMatch("a", sql:escape_char($a) ).

prepare_argument_test() ->
    ?assertMatch("'\\' or 1 = 1 --'", sql:prepare_argument("' or 1 = 1 --")),
    ?assertMatch("'\\' or 1 = 1 --'", sql:prepare_argument('\' or 1 = 1 --')),
    ?assertMatch("55688", sql:prepare_argument(55688)).

prepare_test() ->
    ?assertMatch("select * from what where field = '\\' or 1 = 1 --' order by time;",
		 sql:prepare("select * from what where field = ? order by time;",
			     ["' or 1 = 1 --"])),
    ?assertMatch("select * from what where field = 55688 order by time;",
		 sql:prepare("select * from what where field = ? order by time;",
			     [55688])),
    ?assertMatch({error,
		  {"2 arguments were used but still 2 will be needed",
		   "select * from what where a = ? and b = ? and c = ? and d = ? order by time;",
		   ["' or 1 = 1 --", 55688]}},
		 sql:prepare("select * from what where a = ? and b = ? and c = ? and d = ? order by time;",
			     ["' or 1 = 1 --", 55688])),
    ?assertMatch({error,
		  {"no argument was used but 2 weren't",
		   "select * from what where a = 2 order by time;",
		   ["' or 1 = 1 --", 55688]}},
		 sql:prepare("select * from what where a = 2 order by time;",
			     ["' or 1 = 1 --", 55688])),
    ?assertMatch({error,
		  {"1 argument was used but 1 wasn't",
		   "select * from what where a = ? order by time;",
		   ["' or 1 = 1 --", 55688]}},
		 sql:prepare("select * from what where a = ? order by time;",
			     ["' or 1 = 1 --", 55688])).
