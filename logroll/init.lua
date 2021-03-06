require 'sys'
require 'os'
require 'io'
require 'string'

require 'fn'

logroll = {}

local DEFAULT_LEVEL = 'INFO'
local level_strs = {'DEBUG', 'INFO', 'WARN', 'ERROR'}

for i, label in ipairs(level_strs) do
    logroll[label] = i
end

local function default_formatter(level, ...)
    local msg = nil

    if #{...} > 1 then
        msg = string.format(({...})[1], unpack(fn.rest({...})))
    else
        msg = ({...})[1]
    end

    return string.format("[%s - %s] - %s\n", level_strs[level], os.date("%Y_%m_%d_%X"), msg)
end

local function default_writer(logger, level, ...)
    if level >= logger.level then
        logger.file:write(logger.formatter(level, unpack({...})))
    end
end

local function make_logger(file, options)
    local logger = {options   = options,
                    file      = file,
                    formatter = options.formatter or default_formatter,
                    writer    = options.writer or default_writer,
                    level     = logroll[DEFAULT_LEVEL]
                }

    return fn.reduce(function(lg, level)
        lg[string.lower(level)] = fn.partial(logger.writer, logger, logroll[level])
        return lg
    end,
    logger, level_strs)
end

-- A simple logger to print to STDIO.
function logroll.print_logger(options)
    local options = options or {}
    return make_logger(io.stdout, options)
end

-- A logger that prints to a file.
function logroll.file_logger(path, options)
    local options = options or {}

    if options.file_timestamp then
        -- append timestamp to create unique log file
        path = path .. '-'..os.date("%Y_%m_%d_%X")
    end

    os.execute('mkdir -p "' .. sys.dirname(path) .. '"')

    return make_logger(io.open(path, 'w'), options)
end
