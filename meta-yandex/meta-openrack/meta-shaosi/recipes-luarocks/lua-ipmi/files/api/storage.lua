local ERR = ngx.ERR
local log = ngx.log
local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local cjson = require 'cjson'
local cjson_decode, cjson_encode = cjson.decode, cjson.encode
local gmatch = string.gmatch

local store_db = ngx.shared.db

local _M = { AUTHORIZE = true }

function get_json()
    read_body()
    local body, err = get_body_data()
    if not body then return nil, err end
    local js, err = cjson_decode(body)
    if not js then return nil, err end
    local data = js.data
    if not data then return nil, "No data" end

    return data
end

function _M.get(self)
    local inkey = self.match.key
    if inkey ~= nil then
        local key, data
        data = {}
        for key in gmatch(inkey, '[^,]+') do
            log(ERR, key)
            data[key] = store_db:get(key)
        end
        return cjson_encode({ data = data, status = 'ok', message = '200 OK' })
    end

    return cjson_encode({ status = 'fail', message = '400 NULL REQUEST' })
end

function _M.post(self)
    local js, err = get_json()
    if not js then return err end
    if self.match.key ~= nil then
        store_db:set(self.match.key, js)
        return cjson_encode({ status = 'ok', message = '200 OK' })
    end

    local k, v
    for k, v in pairs(js) do
        local e = store_db:set(k, v)
    end

    return cjson_encode({ status = 'ok', message = '200 OK' })
end

return _M
