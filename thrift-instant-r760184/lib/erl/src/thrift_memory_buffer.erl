%%%-------------------------------------------------------------------
%%% File    : thrift_memory_buffer.erl
%%% Author  : <dreiss@facebook.com>
%%% Description : In-memory transport for thrift
%%%
%%% Created : 27 Aug 2008 by <dreiss@facebook.com>
%%%-------------------------------------------------------------------
-module(thrift_memory_buffer).

-behaviour(gen_server).
-behaviour(thrift_transport).

%% API
-export([new/0, new_transport_factory/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% thrift_transport callbacks
-export([write/2, read/2, flush/1, close/1]).

-record(memory_buffer, {buffer}).

%%====================================================================
%% API
%%====================================================================
new() ->
    case gen_server:start_link(?MODULE, [], []) of
        {ok, Pid} ->
            thrift_transport:new(?MODULE, Pid);
        Else ->
            Else
    end.

new_transport_factory() ->
    {ok, fun() -> new() end}.

%%--------------------------------------------------------------------
%% Function: write(Transport, Data) -> ok
%%
%% Data = iolist()
%%
%% Description: Writes data into the buffer
%%--------------------------------------------------------------------
write(Transport, Data) ->
    gen_server:call(Transport, {write, Data}).

%%--------------------------------------------------------------------
%% Function: flush(Transport) -> ok
%%
%% Description: Flushes the buffer through to the wrapped transport
%%--------------------------------------------------------------------
flush(Transport) ->
    gen_server:call(Transport, flush).

%%--------------------------------------------------------------------
%% Function: close(Transport) -> ok
%%
%% Description: Closes the transport and the wrapped transport
%%--------------------------------------------------------------------
close(Transport) ->
    gen_server:cast(Transport, close).

%%--------------------------------------------------------------------
%% Function: Read(Transport, Len) -> {ok, Data}
%%
%% Data = binary()
%%
%% Description: Reads data through from the wrapped transoprt
%%--------------------------------------------------------------------
read(Transport, Len) when is_integer(Len) ->
    gen_server:call(Transport, {read, Len}).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([]) ->
    {ok, #memory_buffer{buffer = []}}.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({write, Data}, _From, State = #memory_buffer{buffer = Buf}) ->
    {reply, ok, State#memory_buffer{buffer = [Buf, Data]}};

handle_call({read, Len}, _From, State = #memory_buffer{buffer = Buf}) ->
    Binary = iolist_to_binary(Buf),
    Give = min(iolist_size(Binary), Len),
    {Result, Remaining} = split_binary(Binary, Give),
    {reply, {ok, Result}, State#memory_buffer{buffer = Remaining}};

handle_call(flush, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(close, State) ->
    {stop, normal, State};
handle_cast(Msg, State=#memory_buffer{}) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
min(A,B) when A<B -> A;
min(_,B)          -> B.

