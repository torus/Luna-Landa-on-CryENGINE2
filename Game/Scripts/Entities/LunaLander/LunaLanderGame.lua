-- -*- indent-tabs-mode: nil -*-

LunaLanderGame = {
   Properties = {
   },

   Editor = {
      Icon = "vehicle.bmp"
   },

   States = {"Init", "Running", "Finished"},

   Init = {},
   Running = {},
   Finished = {},

   KeyState = {
      Up = false,
      Left = false,
      Right = false,
   }
}

function LunaLanderGame:OnInit ()
   System.Log "LunaLanderGame.OnInit"

   self:GotoState "Init"
end

function LunaLanderGame:OnReset ()
   System.Log "LunaLanderGame.OnReset"

   self:GotoState "Init"
end

function LunaLanderGame.Init.OnBeginState (self)
   System.Log "LunaLanderGame.Init.OnBeginState"

   System.SetCVar ("p_gravity_z", -1)

   local slot = self:LoadObject (1, "objects/characters/animals/turtle/turtle.cdf")
   System.Log ("slot: " .. slot)
   self:DrawSlot (slot, 1)
   self:EnablePhysics (0)
   self:Activate (0)
end

function LunaLanderGame.Running.OnBeginState (self)
   System.Log "LunaLanderGame.Running.OnBeginState"
   self:SetAngles ({x=0, y=0, z=1})
   self:Physicalize (1, PE_RIGID, {mass = 1})
   self:EnablePhysics (1)
   self:Activate (1)
end

local function update_helper (self)
   local task = {}
   local angle = 0
   self.LandingStatus = nil

   local function addtask (...)
      table.insert (task, {...})
   end

   while true do
      if self.LandingStatus then
         if self.LandingStatus.result then
            addtask (System.Log, "Success!")
         else
            addtask (System.Log, "Fail!")
         end
         self.LandingStatus = nil
         break
      end

      if self.KeyState.Up then
         local vec = {}
         RotateVectorAroundR (vec, {x = 0, y = 0, z = 1}, {x = 0, y = 1, z = 0}, angle)
         addtask (self.AddImpulse, self, -1, {x=0, y=0, z=0}, vec, 1)
         addtask (System.Log, "Up")
      end

      if self.KeyState.Right then
         angle = angle + 0.2
         addtask (System.Log, "Right")
      end

      if self.KeyState.Left then
         angle = angle - 0.2
         addtask (System.Log, "Left")
      end

      angle = clamp (angle, -g_Pi2, g_Pi2)

      addtask (self.SetAngles, self, {x=0, y=angle, z=0})

      coroutine.yield (task)
      task = {}
   end

   return task
end

function LunaLanderGame.Running.OnUpdate (self, ...)
   if not self.UpdateCoro then
      self.UpdateCoro = coroutine.create (update_helper)
   end

   if coroutine.status (self.UpdateCoro) ~= "dead" then
      local stat, task = coroutine.resume (self.UpdateCoro, self)

      if stat then
         for i, t in ipairs (task) do
            local func = table.remove (t, 1)
            func (unpack (t))
         end
      else
         System.Error (task)
         self:GotoState "Finished"
      end
   else
      self.UpdateCoro = nil
      self:GotoState "Finished"
   end
end

function LunaLanderGame.Running.OnCollision (self, hitdata)
   local norm = hitdata.normal
   local vel = hitdata.velocity
   local ang = self:GetAngles ()

   self.LandingStatus = {result = false}
end

function LunaLanderGame.Running.OnEndState (self)
   self:Activate (0)
end

function LunaLanderGame.Event_Start (self, ...)
   System.Log "LunaLanderGame.Event_Start"

   self:GotoState "Running"
end

function LunaLanderGame.Event_RotateRight (self, ...)
   System.Log "LunaLanderGame.Event_RotateRight"

   self.KeyState.Right = true
end

function LunaLanderGame.Event_EndRotateRight (self, ...)
   System.Log "LunaLanderGame.Event_EndRotateRight"

   self.KeyState.Right = false
end

function LunaLanderGame.Event_RotateLeft (self, ...)
   System.Log "LunaLanderGame.Event_RotateLeft"

   self.KeyState.Left = true
end

function LunaLanderGame.Event_EndRotateLeft (self, ...)
   System.Log "LunaLanderGame.Event_EndRotateLeft"

   self.KeyState.Left = false
end

function LunaLanderGame.Event_Boost (self)
   System.Log "LunaLanderGame.Event_Boost"

   self.KeyState.Up = true
end

function LunaLanderGame.Event_EndBoost (self)
   System.Log "LunaLanderGame.Event_EndBoost"

   self.KeyState.Up = false
end

function LunaLanderGame.Event_Exit (self)
   System.Log "LunaLanderGame.Event_Exit"
end

LunaLanderGame.FlowEvents = {
   Inputs = {
      Start = {LunaLanderGame.Event_Start, "bool"},
      RotateRight = {LunaLanderGame.Event_RotateRight, "bool"},
      EndRotateRight = {LunaLanderGame.Event_EndRotateRight, "bool"},
      RotateLeft = {LunaLanderGame.Event_RotateLeft, "bool"},
      EndRotateLeft = {LunaLanderGame.Event_EndRotateLeft, "bool"},
      Boost = {LunaLanderGame.Event_Boost, "bool"},
      EndBoost = {LunaLanderGame.Event_EndBoost, "bool"},
      Exit = {LunaLanderGame.Event_Exit, "bool"},
   },

   Outputs = {
   },
}

System.Log "LunaLanderGame.lua loaded"
