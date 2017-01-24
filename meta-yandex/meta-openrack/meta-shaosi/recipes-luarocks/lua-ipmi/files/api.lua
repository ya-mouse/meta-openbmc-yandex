local _M = { AUTHORIZE = true }

function _M.get(self)
    return 'get:'..tostring(self.match.path)
end

function _M.post(self)
    return 'POST:'..tostring(self.match.path)..':'..tostring(self.match.prop)
end

return _M
