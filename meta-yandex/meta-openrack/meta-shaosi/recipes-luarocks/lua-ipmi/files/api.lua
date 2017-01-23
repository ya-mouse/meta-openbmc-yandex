local _M = { AUTHORIZE = true }

function _M.get(self)
    return 'get:'..tostring(self.match.path)
end

return _M
