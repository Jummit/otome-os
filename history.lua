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
      self.reverts = {}
      return name
    end,
    undo = function(self)
      local toRevert = self.history[#self.history - #self.reverts]
      if not toRevert then return end
      local revertAction = {name = "Undid "..toRevert.name, doFun = toRevert.undo, undo = toRevert.doFun}
      table.insert(self.reverts, revertAction)
      revertAction.doFun()
      return revertAction
    end,
    redo = function(self)
      if #self.reverts == 0 then return end
      local toRedo = table.remove(self.reverts)
      toRedo.undo()
      return toRedo
    end,
  }
end
