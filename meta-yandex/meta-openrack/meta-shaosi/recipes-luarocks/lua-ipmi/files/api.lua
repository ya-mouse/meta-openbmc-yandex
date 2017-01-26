local ERR = ngx.ERR
local log = ngx.log
local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local cjson = require 'cjson'
local cjson_decode, cjson_encode = cjson.decode, cjson.encode

local _M = { AUTHORIZE = true }

function _M.get(self)
    return 'API_GET:'..tostring(self.match.paths)
end

function _M.post(self)
    return 'API_POST:'..tostring(self.match.paths)
end

return _M
