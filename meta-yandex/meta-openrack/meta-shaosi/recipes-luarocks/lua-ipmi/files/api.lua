local _M = { AUTHORIZE = true }

function _M.get(self)
    return 'get:'..tostring(self.match.paths)
end

function _M.post(self)
    return 'POST:'..tostring(self.match.paths)
end

return _M
