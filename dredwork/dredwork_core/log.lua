-- dredwork Core — Logger
-- Instance-based logging with replaceable output sink.

local Log = {}
Log.__index = Log

Log.LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4, NONE = 5 }
local LEVEL_NAMES = { "DEBUG", "INFO", "WARN", "ERROR" }

--- Create a new logger instance.
---@param options table|nil { level, sink, prefix }
---@return table Log instance
function Log.new(options)
    local self = setmetatable({}, Log)
    options = options or {}
    self.level = options.level or Log.LEVELS.INFO
    self.sink = options.sink or print
    self.prefix = options.prefix or "[dredwork]"
    return self
end

--- Internal: format and emit a log message if level is met.
function Log:_log(level, msg, ...)
    if level < self.level then return end
    local label = LEVEL_NAMES[level] or "?"
    local formatted = select("#", ...) > 0 and string.format(msg, ...) or msg
    self.sink(string.format("%s [%s] %s", self.prefix, label, formatted))
end

function Log:debug(msg, ...) self:_log(Log.LEVELS.DEBUG, msg, ...) end
function Log:info(msg, ...)  self:_log(Log.LEVELS.INFO, msg, ...)  end
function Log:warn(msg, ...)  self:_log(Log.LEVELS.WARN, msg, ...)  end
function Log:error(msg, ...) self:_log(Log.LEVELS.ERROR, msg, ...) end

return Log
