-- This file was automatically generated for the LuaDist project.

package = "lua-gnuplot"
version = "0.3-1"

-- LuaDist source
source = {
  tag = "0.3-1",
  url = "git://github.com/LuaDist-testing/lua-gnuplot.git"
}
-- Original source
-- source = {
--     url = "https://bitbucket.org/lucashnegri/lua-gnuplot/get/v0.3.tar.gz",
--     md5 = "a4b9111669ed93da6302f2059bc2d2c7",
--     dir = "lucashnegri-lua-gnuplot-168f39263328",
-- }

description = {
    summary    = "Lua interface for gnuplot",
    detailed   = [[
    lua-gnuplot is a small library for using gnuplot in a Lua program. It works by
    generating a gnuplot script from a Lua plot definition and calling the
    gnuplot program for you.
    ]],
    homepage   = "https://bitbucket.org/lucashnegri/lua-gnuplot",
    license    = "MIT",
    maintainer = "Lucas Hermann Negri <lucashnegri@gmail.com>",
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = "builtin",
    modules = {
        ["gnuplot"]         = "gnuplot.lua",
    },
    copy_directories = {},
}