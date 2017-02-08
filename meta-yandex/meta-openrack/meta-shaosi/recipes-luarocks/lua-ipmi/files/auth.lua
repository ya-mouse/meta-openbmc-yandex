#!/usr/bin/lua

local pam = require 'pam'
local ck = require 'resty.cookie'
local cjson = require 'cjson'
local cjson_decode, cjson_encode = cjson.decode, cjson.encode
local rnd_bytes = require 'resty.random'.bytes
local pam_start, pam_auth, pam_end = pam.start, pam.authenticate, pam.endx

local ERR = ngx.ERR
local log = ngx.log
local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local time = ngx.time
local cookie_time = ngx.cookie_time

local sess_db = ngx.shared.auth

local function conversation(messages, creds)
	local responses = {}
        local login, passwd = creds[1], creds[2]

	for i, message in ipairs(messages) do
		local msg_style, msg = message[1], message[2]

		if msg_style == pam.PROMPT_ECHO_OFF then
			-- Assume PAM asks us for the password
			responses[i] = {passwd, 0}
		elseif msg_style == pam.PROMPT_ECHO_ON then
			-- Assume PAM asks us for the username
			responses[i] = {login, 0}
		elseif msg_style == pam.ERROR_MSG then
			log(ERR, "PAM ERROR: " .. msg)
			responses[i] = {"", 0}
		elseif msg_style == pam.TEXT_INFO then
			responses[i] = {"", 0}
		else
			log(ERR, "Unsupported conversation message style: " .. msg_style)
		end
	end

	return responses
end

local _M = {}

-- TODO: better to use POST for create session and DELETE for session destroy
function _M.post(self)
    if self.path == 'login' then
        return _M.login(self)
    elseif self.path == 'logout' then
        return _M.logout(self)
    end
end

function _M.login(self)
    read_body()
    local body, err = get_body_data()
    if not body then ngx.exit(400) end
    local js = cjson_decode(body)
    if not js then ngx.exit(400) end
    local data = js.data
    if not data then ngx.exit(400) end

    local login, passwd = data[1], data[2]
    local ok, sid = authenticate(login, passwd)
    if ok then
         local expires = cookie_time(time() + 3600 * 24) -- 1 day
         local cookie, err = ck:new()
         sess_db:set(sid, '{ login: "'..login..'", group: "root" }', time() + 3600 * 24)
         local ok, err = cookie:set({ key = 'sid', value = sid, secure = false, samesize = 'Strict' }) -- , expires = expires })
         return cjson_encode({ data = "User '"..login.."' logged in" })
    else
         ngx.exit(401)
    end
end

function _M.logout(self)
    local cookie, err = ck:new()
    local sid, err = cookie:get('sid')
    if not err then
         sess_db:delete(sid)
    end
    cookie:set({ key = 'sid', value = 'deleted', expires = 'Thu, 01-Jan-1970 00:00:01 GMT' })
    return cjson_encode({ data = 'User logged out' })
end

function _M.check_sid()
    local cookie, err = ck:new()
    local sid, err = cookie:get('sid')
    if err then return false end
    return sess_db:get(sid) ~= nil
end

function authenticate(login, passwd)
    local h, msg = pam_start("openresty", login, {conversation, { login, passwd }})
    if not h then return false, msg end

    local ok, msg = pam_auth(h)
    if not ok then return false, msg end

    local sid, ok = rnd_bytes(32, "hex")
    if not ok then return false, 'SID generation failed' end

    ok, msg = pam_end(h, pam.SUCCESS)
    if not ok then return false, msg end

    return true, sid
end

return _M
