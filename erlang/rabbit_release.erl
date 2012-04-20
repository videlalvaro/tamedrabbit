%% based on rabbit_prelaunch.erl from rabbitmq-server source code
-module(rabbit_release).

-export([start/0, stop/0]).

-include("rabbit.hrl").

%% TODO remove xmerl when the new rabbitmq_management is released
-define(BaseApps, [rabbit, xmerl]).
-define(ERROR_CODE, 1).

start() ->
    %% Determine our various directories
    [EnabledPluginsFile, PluginsDistDir, UnpackedPluginDir, RabbitHome] =
        init:get_plain_arguments(),
    RootName = UnpackedPluginDir ++ "/rabbit",

    prepare_plugins(EnabledPluginsFile, PluginsDistDir, UnpackedPluginDir),

    %% Build a list of required apps based on the fixed set, and any plugins
    PluginApps = find_plugins(UnpackedPluginDir),
    RequiredApps = ?BaseApps ++ PluginApps,

    %% Build the entire set of dependencies - this will load the
    %% applications along the way
    AllApps = case catch sets:to_list(expand_dependencies(RequiredApps)) of
                  {failed_to_load_app, App, Err} ->
                      terminate("failed to load application ~s:~n~p",
                                [App, Err]);
                  AppList ->
                      AppList
              end,
    AppVersions = [determine_version(App) || App <- AllApps],
    RabbitVersion = proplists:get_value(rabbit, AppVersions),

    %% Build the overall release descriptor
    RDesc = {release,
             {"rabbit", RabbitVersion},
             {erts, erlang:system_info(version)},
             AppVersions},

    %% Write it out to $RABBITMQ_PLUGINS_EXPAND_DIR/rabbit.rel
    rabbit_file:write_file(RootName ++ ".rel", io_lib:format("~p.~n", [RDesc])),

    XRefExclude = [mochiweb],

    %% Compile the script
    systools:make_script(RootName, [silent, {exref, AllApps -- XRefExclude}]),
    ScriptFile = RootName ++ ".script",
    case post_process_script(ScriptFile) of
        ok -> ok;
        {error, Reason} ->
            terminate("post processing of boot script file ~s failed:~n~w",
                      [ScriptFile, Reason])
    end,
    systools:script2boot(RootName),
    %% Make release tarfile
    make_tar(RootName, RabbitHome),
    terminate(0),
    ok.

stop() ->
    ok.

make_tar(Release, RabbitHome) ->
    systools:make_tar(Release,
                      [
                       {dirs, [include, sbin, docs]},
                       {erts, code:root_dir()},
                       {outdir, RabbitHome ++ "/../.."}
                      ]).

determine_version(App) ->
    application:load(App),
    {ok, Vsn} = application:get_key(App, vsn),
    {App, Vsn}.

delete_recursively(Fn) ->
    case rabbit_file:recursive_delete([Fn]) of
        ok                 -> ok;
        {error, {Path, E}} -> {error, {cannot_delete, Path, E}};
        Error              -> Error
    end.

prepare_plugins(EnabledPluginsFile, PluginsDistDir, DestDir) ->
    AllPlugins = rabbit_plugins:find_plugins(PluginsDistDir),
    Enabled = rabbit_plugins:read_enabled_plugins(EnabledPluginsFile),
    ToUnpack = rabbit_plugins:calculate_required_plugins(Enabled, AllPlugins),
    ToUnpackPlugins = rabbit_plugins:lookup_plugins(ToUnpack, AllPlugins),

    Missing = Enabled -- rabbit_plugins:plugin_names(ToUnpackPlugins),
    case Missing of
        [] -> ok;
        _  -> io:format("Warning: the following enabled plugins were "
                        "not found: ~p~n", [Missing])
    end,

    %% Eliminate the contents of the destination directory
    case delete_recursively(DestDir) of
        ok         -> ok;
        {error, E} -> terminate("Could not delete dir ~s (~p)", [DestDir, E])
    end,
    case filelib:ensure_dir(DestDir ++ "/") of
        ok          -> ok;
        {error, E2} -> terminate("Could not create dir ~s (~p)", [DestDir, E2])
    end,

    [prepare_plugin(Plugin, DestDir) || Plugin <- ToUnpackPlugins].

prepare_plugin(#plugin{type = ez, location = Location}, PluginDestDir) ->
    zip:unzip(Location, [{cwd, PluginDestDir}]);
prepare_plugin(#plugin{type = dir, name = Name, location = Location},
               PluginsDestDir) ->
    rabbit_file:recursive_copy(Location,
                               filename:join([PluginsDestDir, Name])).

find_plugins(PluginDir) ->
    [prepare_dir_plugin(PluginName) ||
        PluginName <- filelib:wildcard(PluginDir ++ "/*/ebin/*.app")].

prepare_dir_plugin(PluginAppDescFn) ->
    %% Add the plugin ebin directory to the load path
    PluginEBinDirN = filename:dirname(PluginAppDescFn),
    code:add_path(PluginEBinDirN),

    %% We want the second-last token
    NameTokens = string:tokens(PluginAppDescFn,"/."),
    PluginNameString = lists:nth(length(NameTokens) - 1, NameTokens),
    list_to_atom(PluginNameString).

expand_dependencies(Pending) ->
    expand_dependencies(sets:new(), Pending).
expand_dependencies(Current, []) ->
    Current;
expand_dependencies(Current, [Next|Rest]) ->
    case sets:is_element(Next, Current) of
        true ->
            expand_dependencies(Current, Rest);
        false ->
            case application:load(Next) of
                ok ->
                    ok;
                {error, {already_loaded, _}} ->
                    ok;
                {error, Reason} ->
                    throw({failed_to_load_app, Next, Reason})
            end,
            {ok, Required} = application:get_key(Next, applications),
            Unique = [A || A <- Required, not(sets:is_element(A, Current))],
            expand_dependencies(sets:add_element(Next, Current), Rest ++ Unique)
    end.

post_process_script(ScriptFile) ->
    case file:consult(ScriptFile) of
        {ok, [{script, Name, Entries}]} ->
            NewEntries = lists:flatmap(fun process_entry/1, Entries),
            case file:open(ScriptFile, [write]) of
                {ok, Fd} ->
                    io:format(Fd, "%% script generated at ~w ~w~n~p.~n",
                              [date(), time(), {script, Name, NewEntries}]),
                    file:close(Fd),
                    ok;
                {error, OReason} ->
                    {error, {failed_to_open_script_file_for_writing, OReason}}
            end;
        {error, Reason} ->
            {error, {failed_to_load_script, Reason}}
    end.

process_entry(Entry = {apply,{application,start_boot,[mnesia,permanent]}}) ->
    [{apply,{rabbit,maybe_hipe_compile,[]}},
     {apply,{rabbit,prepare,[]}}, Entry];
process_entry(Entry) ->
    [Entry].

terminate(Fmt, Args) ->
    io:format("ERROR: " ++ Fmt ++ "~n", Args),
    terminate(?ERROR_CODE).

terminate(Status) ->
    case os:type() of
        {unix,  _} -> halt(Status);
        {win32, _} -> init:stop(Status),
                      receive
                      after infinity -> ok
                      end
    end.
