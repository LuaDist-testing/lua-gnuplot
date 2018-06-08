--[[
=================================================================
*
* Copyright (c) 2013 Lucas Hermann Negri
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation files
* (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify,
* merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished
* to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
* BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
* ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* ==================================================================
--]]

local gnuplot = {}

-- ** auxiliary functions **
local temp_files = {}

local function remove_temp_files()
    for _, fname in ipairs(temp_files) do
        os.remove(fname)
    end
end

local function write_temp_file(content)
    local name = os.tmpname()
    local file = io.open(name, 'w')
    file:write(content)
    file:close()
    
    table.insert(temp_files, name)
    
    return name
end

local function add(t, ...)
    table.insert(t, string.format(...))
end

-- which strings should be quoted
local quoted = {
    xlabel      = true,
    ylabel      = true,
    zlabel      = true,
    xformat     = true,
    yformat     = true,
    zformat     = true,
    decimalsign = true,
    output      = true,
    title       = true,
}

local special = {
    xformat     = 'set format x "%s"',
    yformat     = 'set format y "%s"',
}

-- terminal types
gnuplot.terminal = {
    png = "pngcairo enhanced",
    svg = "svg dashed enhanced",
}

local options = {
    -- header
    function(g, code)
        add(code, 'set terminal %s size %d, %d font "%s,%d"',
            gnuplot.terminal[g._type], g.width, g.height, g.fname, g.fsize)
    end,
    
    -- configs
    function(g, code)
        for k, v in pairs(g) do
            if k:sub(1,1) ~= '_' then
                -- string. ex.: set logscale x or set xlabel "X label"
                if type(v) == 'string' then
                    if special[k] then
                        add(code, special[k], v)
                    elseif quoted[k] then
                        add(code, 'set %s "%s"', k, v)
                    else
                        add(code, 'set %s %s', k, v)
                    end
                -- boolean. ex.: set grid
                elseif type(v) == 'boolean' then
                    add(code, '%s %s', v and 'set' or 'unset', k)
                end
            end
        end
    end,
}

-- returns a string with the gnuplot script
function gnuplot.codegen(g, cmd, path)
    g._type  = g.type or path:match("%.([^%.]+)$")
    g.type   = nil
    g.output = path

    local code = {}
    for _, f in ipairs(options) do
        f(g, code)
    end
    
    local plot_cmd = {}
    
    for i = 1, #g.data do
        local d    = g.data[i]
        local u    = d.file and 'u ' .. table.concat(d.using, ':') or ''
        local name = d.file and string.format('"%s"', d[1]) or d[1]
        add(plot_cmd, '%s %s w %s lt %d lw %d t "%s"',
            name, u, d.with, d.type or i, d.width, d.title or '')
    end
    add(code, cmd .. ' ' .. table.concat(plot_cmd, ', '))
    
    return table.concat(code, '\n')
end

function gnuplot.do_plot(g, cmd, path)
    local code = gnuplot.codegen(g, cmd, path)
    local name = write_temp_file( code )
    
    os.execute( string.format("%s %s",  gnuplot.bin, name) )
    
    return g
end

-- 2D plot
function gnuplot.plot(g, path)
    return gnuplot.do_plot(g, "plot", path)
end

-- 3D plot
function gnuplot.splot(g, path)
    return gnuplot.do_plot(g, "splot", path)
end

-- ** Constructor and mt **

local plot_mt
plot_mt = {
    -- constructor
    __call = function(_, p)
        setmetatable(p, plot_mt)
        return p
    end,

    -- defaults
    __index = {
        width  = 500,
        height = 400,
        fname  = "Arial",
        fsize  = 12,
        plot   = gnuplot.plot,
        splot  = gnuplot.splot,
        bin    = 'gnuplot',
        grid   = 'back',
        xlabel = 'X',
        ylabel = 'Y'
    },
}

setmetatable(gnuplot, plot_mt)
setmetatable(plot_mt, {__gc = remove_temp_files }) -- ugly

-- ** Data to plot **

local datamt = {
    -- defaults
    __index = {
        using = {1,2},
        width = 2,
        with  = 'l',
    }
}

-- native gnuplot function
function gnuplot.gpfunc(arg)
    setmetatable(arg, datamt)
    return arg
end

-- simple: data already in a file
function gnuplot.file(arg)
    setmetatable(arg, datamt)
    arg.file = true
    return arg
end

-- data is in a table that must be saved to a temp file
function gnuplot.array(arg)
    local array = {}
    local data  = arg[1]
    
    for line = 1, #data[1] do
        local aux = {}
        for col = 1, #data do
            table.insert(aux, data[col][line])
        end
        table.insert(array, table.concat(aux, ' '))
    end
    
    local lines = table.concat(array, '\n')
    arg[1] = write_temp_file(lines)
    return gnuplot.file(arg)
end

-- generate data from a function, then save it to a temp file
function gnuplot.func(arg)
    local array = { {}, {} }
    local func  = arg[1]
    local range = arg.range or {-5, 5, 0.1}
    
    for x = range[1], range[2], range[3] do
        table.insert(array[1], x       )
        table.insert(array[2], func(x) )
    end

    arg[1] = array
    return gnuplot.array(arg)
end

return gnuplot
