--------------------
--    History     --
--------------------

local join = require("utils").join

return function()
	return {
		history = {},
		reverts = {},
		addAction = function(self, name, doFun, undo)
		  self.history = join(self.history, self.reverts)
		  table.insert(self.history, {name = name, doFun = doFun, undo = undo})
		  doFun()
		  print(name)
		  self.reverts = {}
		end
	}
end
