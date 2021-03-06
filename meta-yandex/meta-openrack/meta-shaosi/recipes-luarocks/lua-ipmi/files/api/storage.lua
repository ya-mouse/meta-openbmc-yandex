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
    if not body then return nil, 'body: '..tostring(err) end
    local js, err = cjson_decode(body)
    if not js then return nil, 'decode: '..tostring(err) end
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
            -- log(ERR, key)
            data[key] = store_db:get(key)
        end
        return cjson_encode({ data = data, status = 'ok', message = '200 OK' })
    end

    return cjson_encode({ status = 'fail', message = '400 NULL REQUEST' })
end

function _M.post(self)
    local js, err = get_json()
    if not js then return cjson_encode({ status = 'fail', message = '400 BAD', error = err }) end

    if self.match.key ~= nil then
        local msg
        if type(js) == 'table' then
            msg = store_db:set(self.match.key, js['value'], js['duration'] or 0.0)
        else
            msg = store_db:set(self.match.key, js)
        end
        return cjson_encode({ status = 'ok', message = '200 OK', msg = tostring(msg) })
    end

    local k, v
    for k, v in pairs(js) do
        if type(v) == 'table' then
           local e = store_db:set(k, v['value'], v['duration'] or 0.0)
        else
           local e = store_db:set(k, v)
        end
    end

    return cjson_encode({ status = 'ok', message = '200 OK' })
end

function _M.delete(self)
    if self.match.key == nil then
         return cjson_encode({ status = 'fail', message = '400 BAD', error = 'No key specified' })
    end
    store_db:delete(self.match.key)
    return cjson_encode({ status = 'ok', message = '200 OK' })
end

return _M
