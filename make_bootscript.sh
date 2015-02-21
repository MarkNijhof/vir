#!/usr/bin/env escript
%% -*- mode:erlang;tab-width:4;erlang-indent-level:4;indent-tabs-mode:nil -*-

main([App]) ->
    code:add_paths(dirs_in("deps/*/ebin")),
    code:add_paths(dirs_in("ebin")),

    make_boot(App),

    ok.

make_boot(AppName) ->

    io:format("~s...~n", [AppName]),

    {ok, [{application, _Name, AppConfig}]} = file:consult(filename:join(["src", AppName ++ ".app.src"])),

    {applications, Applications} = lists:keyfind(applications, 1, AppConfig),

    ReltoolConfig = [{config, {sys, [
                                     {lib_dirs, ["../", "deps"]},
                                     {erts, [{mod_cond, derived}, {app_file, strip}]},
                                     {rel, AppName, "1", Applications ++ [list_to_atom(AppName)]},
                                     {boot_rel, AppName},
                                     {profile, embedded},
                                     {excl_archive_filters, [".*"]}, %% Do not archive built libs
                                     {excl_sys_filters, ["^bin/.*", "^erts.*/bin/(dialyzer|typer)",
                                                         "^erts.*/(doc|info|include|lib|man|src)"]},
                                     {excl_app_filters, ["\.gitignore"]},
                                     {app, list_to_atom(AppName), [{mod_cond, app}, {incl_cond, include}]},
                                     {app, hipe, [{incl_cond, exclude}]}
                                    ]}}],

    {ok, Server} = reltool:start_server(ReltoolConfig),

    {ok, Script} = reltool:get_script(Server, AppName),

    file:write_file(filename:join(["ebin", AppName ++ ".script"]), io_lib:format("~p.", [Script])),

    systools:script2boot(filename:join(["ebin", AppName])).

dirs_in(Wildcard) ->
    [Dir || Dir <- filelib:wildcard(Wildcard),
    filelib:is_dir(Dir), filelib:is_file(filename:join([Dir, "relx.config"]))].
