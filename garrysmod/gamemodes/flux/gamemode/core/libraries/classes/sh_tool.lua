--[[
  Sandbox's tools copy-pasta.
  Because sandbox only lets you create tools
  from entities folder, which isn't exactly
  acceptable for us.
--]]

--[[
  For tool object documentation, as well as tutorials on
  creating gmod tools, go to gmod wiki. Our wiki only covers
  extras added by Flux.
--]]

class "CTool"

function CTool:MakeGhostEntity(model, pos, angle)
  util.PrecacheModel(model)

  if (SERVER and !game.SinglePlayer()) then return end
  if (CLIENT and game.SinglePlayer()) then return end
  if (self.GhostEntityLastDelete and self.GhostEntityLastDelete + 0.1 > CurTime()) then return end

  -- Release the old ghost entity
  self:ReleaseGhostEntity()

  -- Don't allow ragdolls/effects to be ghosts
  if (!util.IsValidProp(model)) then return end

  if CLIENT then
    self.GhostEntity = ents.CreateClientProp(model)
  else
    self.GhostEntity = ents.Create("prop_physics")
  end

  -- If there's too many entities we might not spawn..
  if (!IsValid(self.GhostEntity)) then
    self.GhostEntity = nil

    return
  end

  self.GhostEntity:SetModel(model)
  self.GhostEntity:SetPos(pos)
  self.GhostEntity:SetAngles(angle)
  self.GhostEntity:Spawn()
  self.GhostEntity:SetSolid(SOLID_VPHYSICS)
  self.GhostEntity:SetMoveType(MOVETYPE_NONE)
  self.GhostEntity:SetNotSolid(true)
  self.GhostEntity:SetRenderMode(RENDERMODE_TRANSALPHA)
  self.GhostEntity:SetColor(Color(255, 255, 255, 150))
end

function CTool:StartGhostEntity(ent)
  if (SERVER and !game.SinglePlayer()) then return end
  if (CLIENT and game.SinglePlayer()) then return end

  self:MakeGhostEntity(ent:GetModel(), ent:GetPos(), ent:GetAngles())
end

function CTool:ReleaseGhostEntity()
  if (self.GhostEntity) then
    if (!IsValid(self.GhostEntity)) then self.GhostEntity = nil return end
    self.GhostEntity:Remove()
    self.GhostEntity = nil
    self.GhostEntityLastDelete = CurTime()
  end

  -- This is unused!
  if (self.GhostEntities) then
    for k,v in pairs(self.GhostEntities) do
      if (IsValid(v)) then v:Remove() end
      self.GhostEntities[k] = nil
    end

    self.GhostEntities = nil
    self.GhostEntityLastDelete = CurTime()
  end

  -- This is unused!
  if (self.GhostOffset) then
    for k,v in pairs(self.GhostOffset) do
      self.GhostOffset[k] = nil
    end
  end
end

function CTool:UpdateGhostEntity()
  if (self.GhostEntity == nil) then return end
  if (!IsValid(self.GhostEntity)) then self.GhostEntity = nil return end

  local trace = self:GetOwner():GetEyeTrace()
  if (!trace.Hit) then return end

  local Ang1, Ang2 = self:GetNormal(1):Angle(), (trace.HitNormal * -1):Angle()
  local TargetAngle = self:GetEnt(1):AlignAngles(Ang1, Ang2)

  self.GhostEntity:SetPos(self:GetEnt(1):GetPos())
  self.GhostEntity:SetAngles(TargetAngle)

  local TranslatedPos = self.GhostEntity:LocalToWorld(self:GetLocalPos(1))
  local TargetPos = trace.HitPos + (self:GetEnt(1):GetPos() - TranslatedPos) + trace.HitNormal

  self.GhostEntity:SetPos(TargetPos)
end

function CTool:UpdateData()
  self:SetStage(self:NumObjects())
end

function CTool:SetStage(i)
  if SERVER then
    self:GetWeapon():SetNWInt("Stage", i, true)
  end
end

function CTool:GetStage()
  return self:GetWeapon():GetNWInt("Stage", 0)
end

function CTool:SetOperation(i)
  if SERVER then
    self:GetWeapon():SetNWInt("Op", i, true)
  end
end

function CTool:GetOperation()
  return self:GetWeapon():GetNWInt("Op", 0)
end

-- Clear the selected objects
function CTool:ClearObjects()
  self:ReleaseGhostEntity()
  self.Objects = {}
  self:SetStage(0)
  self:SetOperation(0)
end

function CTool:GetEnt(i)
  if (!self.Objects[i]) then return NULL end

  return self.Objects[i].Ent
end

function CTool:GetPos(i)
  if (self.Objects[i].Ent:EntIndex() == 0) then
    return self.Objects[i].Pos
  else
    if (IsValid(self.Objects[i].Phys)) then
      return self.Objects[i].Phys:LocalToWorld(self.Objects[i].Pos)
    else
      return self.Objects[i].Ent:LocalToWorld(self.Objects[i].Pos)
    end
  end
end

-- Returns the local position of the numbered hit
function CTool:GetLocalPos(i)
  return self.Objects[i].Pos
end

-- Returns the physics bone number of the hit (ragdolls)
function CTool:GetBone(i)
  return self.Objects[i].Bone
end

function CTool:GetNormal(i)
  if (self.Objects[i].Ent:EntIndex() == 0) then
    return self.Objects[i].Normal
  else
    local norm

    if (IsValid(self.Objects[i].Phys)) then
      norm = self.Objects[i].Phys:LocalToWorld(self.Objects[i].Normal)
    else
      norm = self.Objects[i].Ent:LocalToWorld(self.Objects[i].Normal)
    end

    return norm - self:GetPos(i)
  end
end

-- Returns the physics object for the numbered hit
function CTool:GetPhys(i)
  if (self.Objects[i].Phys == nil) then
    return self:GetEnt(i):GetPhysicsObject()
  end

  return self.Objects[i].Phys
end

-- Sets a selected object
function CTool:SetObject(i, ent, pos, phys, bone, norm)
  self.Objects[i] = {}
  self.Objects[i].Ent = ent
  self.Objects[i].Phys = phys
  self.Objects[i].Bone = bone
  self.Objects[i].Normal = norm

  -- Worldspawn is a special case
  if (ent:EntIndex() == 0) then
    self.Objects[i].Phys = nil
    self.Objects[i].Pos = pos
  else
    norm = norm + pos

    -- Convert the position to a local position - so it's still valid when the object moves
    if (IsValid(phys)) then
      self.Objects[i].Normal = self.Objects[i].Phys:WorldToLocal(norm)
      self.Objects[i].Pos = self.Objects[i].Phys:WorldToLocal(pos)
    else
      self.Objects[i].Normal = self.Objects[i].Ent:WorldToLocal(norm)
      self.Objects[i].Pos = self.Objects[i].Ent:WorldToLocal(pos)
    end
  end

  if SERVER then
    -- Todo: Make sure the client got the same info
  end
end

-- Returns the number of objects in the list
function CTool:NumObjects()
  if CLIENT then
    return self:GetStage()
  end

  return #self.Objects
end

-- Returns the number of objects in the list
function CTool:GetHelpText()
  return "#tool."..GetConVarString("gmod_toolmode").."."..self:GetStage()
end

if CLIENT then
  -- Tool should return true if freezing the view angles
  function CTool:FreezeMovement()
    return false
  end

  -- The tool's opportunity to draw to the HUD
  function CTool:DrawHUD() end
end

function CTool:CTool()
  self.Mode = nil
  self.SWEP = nil
  self.Owner = nil
  self.ClientConVar = {}
  self.ServerConVar = {}
  self.Objects = {}
  self.Stage = 0
  self.Message = "start"
  self.LastMessage = 0
  self.AllowedCVar = 0
end

function CTool:CreateConVars()
  local mode = self:GetMode()

  if CLIENT then
    for cvar, default in pairs(self.ClientConVar) do
      CreateClientConVar(mode.."_"..cvar, default, true, true)
    end

    return
  end

  if SERVER then
    self.AllowedCVar = CreateConVar("toolmode_allow_"..mode, 1, FCVAR_NOTIFY)
  end
end

function CTool:GetServerInfo(property)
  local mode = self:GetMode()

  return GetConVarString(mode.."_"..property)
end

function CTool:BuildConVarList()
  local mode = self:GetMode()
  local convars = {}

  for k, v in pairs(self.ClientConVar) do convars[mode.."_"..k] = v end

  return convars
end

function CTool:GetClientInfo(property)
  return self:GetOwner():GetInfo(self:GetMode().."_"..property)
end

function CTool:GetClientNumber(property, default)
  return self:GetOwner():GetInfoNum(self:GetMode().."_"..property, tonumber(default) or 0)
end

function CTool:Allowed()
  if CLIENT then return true end

  return self.AllowedCVar:GetBool()
end

-- Now for all the CTool redirects

function CTool:Init() end

function CTool:GetMode() return self.Mode end
function CTool:GetSWEP() return self.SWEP end
function CTool:GetOwner() return self:GetSWEP().Owner or self.Owner end
function CTool:GetWeapon()  return self:GetSWEP().Weapon or self.Weapon end

function CTool:LeftClick() return false end
function CTool:RightClick() return false end
function CTool:Reload() self:ClearObjects() end
function CTool:Deploy() self:ReleaseGhostEntity() return end
function CTool:Holster() self:ReleaseGhostEntity() return end
function CTool:Think() self:ReleaseGhostEntity() end

--[[---------------------------------------------------------
  Checks the objects before any action is taken
  This is to make sure that the entities haven't been removed
-----------------------------------------------------------]]
function CTool:CheckObjects()
  for k, v in pairs(self.Objects) do
    if (!v.Ent:IsWorld() and !v.Ent:IsValid()) then
      self:ClearObjects()
    end
  end
end

function CTool:__tostring()
  return "Tool ["..(self.id or "Unknown").."]"
end

Tool = CTool
