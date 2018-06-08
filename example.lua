#! /usr/bin/env lua

local gp = require('gnuplot')
-- gp.bin = '/usr/local/bin/mygnuplot'

local g = gp{
    -- all optional, with sane defaults
    width  = 600,
    height = 400,
    xlabel = "X axis",
    ylabel = "Y axis",
    key    = "top left",
    
    data = {
        gp.file {   -- plot from a file
            "myfile",                   -- file path
            title = "Title 1",          -- optional
        },
        
        gp.array {  -- plot from an 'array-like' thing in memory. Could be a
                    -- numlua matrix, for example.
            {
                {0,1,2,3,4,5,6,7,8,9},  -- x
                {3,4,5,6,7,8,9,8,7,6}   -- y
            },
            
            title = "Title 2",          -- optional
            using = {1,2},              -- optional
            with  = 'linespoints'       -- optional
        },
        
        gp.func {   -- plot from a Lua function
            function(x)                 -- function to plot
                return 3* math.sin(2*x) + 4
            end,
            
            range = {-2, 10, 0.01},     -- optional
            width = 3,                  -- optional
        },
        
        gp.gpfunc { -- plot from a native gnuplot function
            "2.5*sin(1.8*x) + 3",
            width = 2,
        },
    }    
}:plot('output.png')

-- plot with other terminals
g:plot('output.svg')
