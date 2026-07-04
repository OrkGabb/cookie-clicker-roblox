--!strict
local Maid = {}
Maid.__index = Maid
export type Maid = typeof(setmetatable({} :: { _tasks: { any } }, Maid))
function Maid.new(): Maid
	return setmetatable({ _tasks = {} :: { any } }, Maid) :: any
end
function Maid:Give<T>(task: T): T
	table.insert(self._tasks :: { any }, task)
	return task
end
function Maid:GiveAll(...: any): ()
	for i = 1, select("#", ...) do
		self:Give(select(i, ...))
	end
end
function Maid:DoCleaning(): ()
	local tasks = self._tasks :: { any }
	for i = #tasks, 1, -1 do
		local t = tasks[i]
		if typeof(t) == "RBXScriptConnection" then
			t:Disconnect()
		elseif typeof(t) == "Instance" then
			t:Destroy()
		elseif typeof(t) == "function" then
			t()
		elseif typeof(t) == "table" then
			local tAny: any = t
			if tAny.Destroy then
				tAny:Destroy()
			elseif tAny.Disconnect then
				tAny:Disconnect()
			end
		end
		tasks[i] = nil
	end
end
function Maid:Destroy(): ()
	self:DoCleaning()
end
return Maid
