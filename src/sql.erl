-module(sql).
-export([ prepare/2,
	  prepare_argument/1,
	  escape_char/1
	]).

-spec prepare(SQLTemplate :: string(), Args :: list()) ->
		     PreparedSQL :: string() | {error, Reason :: term()}.
%%      By using some SQL template like "select * from what where field = ?;"
%% then it determines if there are such many placeholders '?' for arguments
%% and form the SQL string.
%%      Note the adjacent '?'s means a placeholder.
prepare(SQLTemp, Args) when is_list(SQLTemp) andalso is_list(Args) ->
    TempList = string:tokens(SQLTemp, "?"),
    case { erlang:length(TempList), erlang:length(Args) } of
	{M, N} when M =:= N+1 ->
	    {ok, SQL} =
		lists:foldl(fun( Str, {[], Acc} ) ->
				    {ok, string:join(lists:reverse([Str|Acc]),"")};
			       ( Str, {[Arg|Args1], Acc} ) ->
				    {Args1, [prepare_argument(Arg), Str|Acc]}
			    end, {Args, ""}, TempList),
	    SQL;
	{M, N} when M > N+1 ->
	    N1 = M - N - 1,
	    {error,
	     {format_string(
		"~w argument~s used but still ~w will be needed",
		[ if N =:= 0 -> no; true -> N end,
		  if N =< 1 -> ' was'; true -> 's were' end,
		  N1
		]),
	      SQLTemp, Args }};
	{M, N} ->
	    N1 = N + 1 - M,
	    N2 = N - N1,
	    {error,
	     {format_string(
		"~w argument~s used but ~w ~s",
		[ if N2 =:= 0 -> no; true -> N2 end,
		  if N2 =< 1 -> ' was'; true -> 's were' end,
		  N1,
		  if N1 =< 1 -> 'wasn\'t'; true -> 'weren\'t' end
		]),
	      SQLTemp, Args }}
    end.
	    

%% -----------------------
%% private
%% -----------------------

-spec prepare_argument(term()) -> string().
prepare_argument(N) when is_number(N) ->
    format_string("~w", [N]);
prepare_argument(A) when is_atom(A) ->
    Str = format_string("~s", [A]),
    concat_string(["'", escape_string(Str), "'"]);
prepare_argument(S) when is_list(S) ->
    concat_string(["'", escape_string(S), "'"]).

format_string(StrTemp, Args) ->
    lists:flatten(io_lib:format(StrTemp, Args)).

concat_string(StrList) when is_list(StrList) ->
    lists:flatten(string:join(StrList, ""), "").

escape_string(Str) ->
    lists:map(fun(Char) -> escape_char(Char) end, Str).

-spec escape_char(char()) -> string().
escape_char($\0) -> "\\0"; 
escape_char($\b) -> "\\b";
escape_char($\t) -> "\\t";
escape_char($\n) -> "\\n";
escape_char($\r) -> "\\r";
escape_char($\z) -> "\\z";
escape_char($\") -> "\\\"";
escape_char($\x{25}) -> "\\%";
escape_char($\') -> "\\'";
escape_char($\\) -> "\\\\";
escape_char($\_) -> "\\_";
escape_char(Any) when is_number(Any) ->
    lists:flatten(io_lib:format("~c", [Any])).
