--!strict
type Callback = (...any) -> ()
type ConnectionData = { callback: Callback, active: boolean }
export type Connection = {
	Disconnect: (self: Connection) -> (),
}
export type Signal = {
	Connect:  (self: Signal, callback: Callback) -> Connection,
	Once:     (self: Signal, callback: Callback) -> Connection,
	Fire:     (self: Signal, ...any) -> (),
	Destroy:  (self: Signal) -> (),
}
local Signal = {}
Signal.__index = Signal
function Signal.new(): Signal
	return setmetatable({ _list = {} :: { ConnectionData } }, Signal) :: any
end
function Signal:Connect(callback: Callback): Connection
	local data: ConnectionData = { callback = callback, active = true }
	table.insert(self._list :: { ConnectionData }, data)
	return {
		Disconnect = function(_self: Connection)
			data.active = false
		end,
	}
end
function Signal:Once(callback: Callback): Connection
	local conn: Connection
	conn = self:Connect(function(...)
		conn:Disconnect()
		callback(...)
	end)
	return conn
end
function Signal:Fire(...)
	for _, data in ipairs(self._list :: { ConnectionData }) do
		if data.active then
			task.spawn(data.callback, ...)
		end
	end
	-- sweep dead entries
	local list = self._list :: { ConnectionData }
	for i = #list, 1, -1 do
		if not list[i].active then
			table.remove(list, i)
		end
	end
end
function Signal:Destroy()
	table.clear(self._list :: { ConnectionData })
end
return Signal
