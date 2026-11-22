
AddCSLuaFile()

-- Network variable names
local bonjumpscare_damageprevention = "BonHost_ds_jumpscare"
local Bon_bonClicking_ds = "Bon_bonClicking_ds"
local Bon_playerClicking_ds = "Bon_playerClicking_ds"
local bon_gameduration = "bon_gameduration"

local player_bonhost = "player_bonhost"

-- variables for the phases
local phase1 = 0 
local phase2 = 1
local phase3 = 2

local gameduration = 5

local speedgainpercentage = (phase2 * 1.2) + phase2

-- CCTV Camera System variables
local camera_id = 0

-- CCTV Camera System Functions (defined globally)
local function CreateCCTVCamera(ent)
    if not SERVER then return end
    
    --print("[BON PILL DEBUG] Attempting to create CCTV camera...")
    
    if not IsValid(ent) then 
        --print("[BON PILL DEBUG] Pill entity is not valid!")
        return 
    end
    
    -- Check if CCTV Camera System addon is available
    if not weapons.Get("ca_tablet") then
        --print("[BON PILL DEBUG] CCTV Camera System addon not found!")
        return
    end
    
    -- Increment camera ID
    camera_id = camera_id + 1
    
    -- Create the camera entity
    local ca_camera = ents.Create("ca_camera")
    if not IsValid(ca_camera) then 
        --print("[BON PILL DEBUG] Failed to create CCTV camera")
        return 
    end
    
    local puppet = ent:GetPuppet()
    if not IsValid(puppet) then
        --print("[BON PILL DEBUG] Puppet is not valid!")
        ca_camera:Remove()
        return
    end
    
    -- Get head bone
    local headBone = puppet:LookupBone("Head")
    --print("[BON PILL DEBUG] Head bone index: " .. tostring(headBone))
    
    -- Make camera invisible
    ca_camera:SetRenderMode(RENDERMODE_NONE)
    ca_camera:SetNoDraw(true)
    ca_camera:DrawShadow(false)
    
    -- Set camera name
    ca_camera:SetCameraName("BON_PILL_VISION_" .. camera_id)
    
    -- Set initial position and angles
    ca_camera:SetPos(puppet:GetPos())
    ca_camera:SetAngles(puppet:GetAngles())
    
    -- Spawn the camera
    ca_camera:Spawn()
    
    -- Set collision properties
    ca_camera:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    ca_camera:SetSolid(SOLID_NONE)


    -- a comment from Nick, why would Bon not have his headbone?

    -- Attach to head bone if available
    if headBone and headBone >= 0 then
        -- Attach to head bone
        ca_camera:FollowBone(puppet, headBone)
        ca_camera:AddEffects(EF_FOLLOWBONE)
        
        -- Set local position (centered in head)
        ca_camera:SetLocalPos(Vector(5, 10, -10)) 
        
        -- Set local angles for proper view
        ca_camera:SetLocalAngles(Angle(90, 180, 90))
        
        --print("[BON PILL DEBUG] Camera attached to head bone " .. headBone .. " - centered in head")
    else
        --print("[BON PILL DEBUG] Head bone not found! Using fallback attachment")
        
        ca_camera:SetParent(puppet)
        ca_camera:SetLocalPos(Vector(5, 0, 65)) 
        ca_camera:SetLocalAngles(Angle(90, 180, 90)) 
    end
    
    -- Store camera reference
    ent.CCTVCamera = ca_camera
    ent.CameraID = camera_id
    
    --print("[BON PILL DEBUG] CCTV Camera created! EntIndex: " .. ca_camera:EntIndex())
    
    -- Debug position after creation
    timer.Simple(1, function()
        if IsValid(ca_camera) and IsValid(puppet) then
            --print("[BON PILL DEBUG] Final camera position: " .. tostring(ca_camera:GetPos()))
            --print("[BON PILL DEBUG] Puppet head position: " .. tostring(puppet:GetPos() + puppet:GetUp() * 65))
        end
    end)
    
    -- Sync cameras with all players
    timer.Simple(0.5, function()
        for _, ply in pairs(player.GetAll()) do
            if IsValid(ply) then
                ply:ConCommand("ca_cams_sync_server")
            end
        end
    end)
    
    return ca_camera
end

local function RemoveCCTVCamera(ent)
    if not SERVER then return end
    
    if IsValid(ent.CCTVCamera) then
        --print("[BON PILL DEBUG] Removing CCTV Camera ID: " .. tostring(ent.CameraID))
        ent.CCTVCamera:Remove()
        ent.CCTVCamera = nil
        ent.CameraID = nil
        
        -- Sync cameras after removal
        timer.Simple(0.1, function()
            for _, ply in pairs(player.GetAll()) do
                if IsValid(ply) then
                    ply:ConCommand("ca_cams_sync_server")
                end
            end
        end)
    end
end

hook.Add( "PlayerFootstep", "CustomFootstep", function( ply, pos, foot, sound, volume, rf )
	local ent = pk_pills.getMappedEnt(ply) 
	if IsValid(ent) and ent.formTable and ent.formTable._bon_pill_ds_withered then
		return true
	end
end )

hook.Add( "PreRegisterSENT", "pill_bon_overide_puppet", function( ent, class )
    if class == "pill_puppet" then
        local PuppetEntity = table.Copy(ent)
        
        PuppetEntity.Type = "anim"
        PuppetEntity.AutomaticFrameAdvance = true
        PuppetEntity.Think = function(self)
            self:NextThink(CurTime())
            return true
        end

        scripted_ents.Register( PuppetEntity, "pill_bon_overide_puppet" )
    end
end )


hook.Add("OnEntityCreated", "bon_modifiedwalkrunspeed_withered", function(ent)
    timer.Simple(0.01, function()
        if !IsValid(ent) then return end

        if ent:GetClass() == "pill_ent_costume" then
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if ent.formTable._bon_pill_ds_withered == "IT\'S BONNET" then


                if SERVER then
                    PuppetEntity:Remove()
                    
                    local puppet = ents.Create("pill_bon_overide_puppet")
                    puppet:SetModel(ent.formTable.model or "models/Humans/corpse1.mdl")
                    
                    if isfunction(puppet.SetPillForm) then
                        puppet:SetPillForm(ent:GetPillForm())
                    end

                    if isfunction(puppet.SetPillCostume) then
                        puppet:SetPillCostume(ent)
                    end

                    if isfunction(puppet.SetPillUser) then
                        puppet:SetPillUser(entityply)
                    end

                    puppet:Spawn()

                    ent:DeleteOnRemove(puppet)
                    ent:SetPuppet(puppet)

                    PuppetEntity = puppet
                end
                
                -- Initialize CCTV Camera for Bon
                if SERVER then
                    --timer.Simple(0.2, function()
                        ---if IsValid(ent) then
                    CreateCCTVCamera(ent)
                        --end
                    --end)
                end

                timer.Simple(0.1, function()
                    if !IsValid(ent) then return end

                    if ent:GetPillUser():IsPlayer() and SERVER then
                        net.Start("Gentoi_bon_CameraCode_n_withered")
                        net.WriteEntity(ent)
                        net.Send(ent:GetPillUser())
                    end
                end)

                local self = ent
                ent.Think = function()
                    local currentanim = 'idle'
                    local ply = self:GetPillUser()
                    local puppet = self:GetPuppet()
                    if not IsValid(puppet) or not IsValid(ply) then return end
                    local vel = ply:GetVelocity():Length()

                    if SERVER then
                        --Anims
                        local anims = table.Copy(self.formTable.anims.default or {})
                        table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
                        local anim
                        --local useSeqVel=true
                        local overrideRate

                        if (not self.anim or not anims[self.anim]) then
                            self.animFreeze = nil
                            self.animStart = nil
                        end

                        if self.animFreeze and not self.plyFrozen then
                            self.plyFrozen = true
                        elseif not self.animFreeze and self.plyFrozen then
                            self.plyFrozen = nil
                        end

                        if self.anim and anims[self.anim] then
                            anim = anims[self.anim]
                            overrideRate = anims[self.anim .. "_rate"] or 1
                            local cycle = puppet:GetCycle()

                            if not self.animStart then
                                if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                                    self.anim = nil
                                    self.animCycle = nil

                                    if self.animFreeze then
                                        self.animFreeze = nil
                                    end
                                elseif self.animCycle then
                                    self.animCycle = cycle
                                end
                            end
                        elseif self.tickAnim and anims[self.tickAnim] then
                            anim = anims[self.tickAnim]
                            overrideRate = anims[self.tickAnim .. "_rate"] or 1
                            self.tickAnim = nil
                        elseif self.burrowed then
                            anim = anims["burrow_loop"]
                        elseif ply:WaterLevel() > 2 then
                            anim = anims["swim"] or anims["glide"] or anims["idle"]
                        elseif ply:IsOnGround() then
                            if ply:Crouching() then
                                if vel > ply:GetCrouchedWalkSpeed() / 4 then
                                    anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                                else
                                    anim = anims["crouch"] or anims["idle"]
                                end
                            else
                                if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                                    anim = anims["run"] or anims["walk"] or anims["idle"]
                                elseif vel > ply:GetWalkSpeed() / 4 then
                                    anim = anims["walk"] or anims["idle"]
                                else
                                    anim = anims["idle"]
                                end
                            end
                        else
                            anim = anims["glide"] or anims["idle"]
                        end

                        if anim == anims["idle"] or anim == anims["crouch"] then
                            overrideRate = 1
                        end
                        self:SetNWString("Animlastplayed", anim)

                        local ShouldAlternate = table.Copy(self.formTable.anims.ShouldAlternate or {})
                        if type(ShouldAlternate[anim]) == "function" and ShouldAlternate[anim](self) then
                            if ShouldAlternate[anim](self) ~= nil and isstring(ShouldAlternate[anim](self)) then
                                
                                anim = ShouldAlternate[anim](self)
                            end
                        end

                        if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then
                            puppet:ResetSequence(puppet:LookupSequence(anim))
                            puppet:SetCycle(0)
                            self.animCycle = 0
                        end

                        self.animStart = nil
                        local seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                        --if true then
                        if self.formTable.movePoseMode ~= "xy" and self.formTable.movePoseMode ~= "xy-bot" and not overrideRate then
                            local rate = overrideRate or vel / seq_vel

                            --goofy limitation (floods console with errors if above 12!)
                            if rate > 12 then
                                rate = 12
                            end

                            puppet:SetPlaybackRate(rate)
                        else
                            --puppet:SetPlaybackRate(1)
                        end

                        --print(puppet:GetCycle())


                            if self.formTable.movePoseMode then
                            end

                        --Aimage
                        if self.formTable.aim then
                            if self.formTable.aim.xPose then
                                local yaw = math.AngleDifference(ply:EyeAngles().y, puppet:GetAngles().y)

                                if self.formTable.aim.xInvert then
                                    yaw = -yaw
                                end

                                puppet:SetPoseParameter(self.formTable.aim.xPose, yaw)
                            end

                            if self.formTable.aim.yPose then
                                local pitch = math.AngleDifference(ply:EyeAngles().p, puppet:GetAngles().p)

                                if self.formTable.aim.yInvert then
                                    pitch = -pitch
                                end

                                puppet:SetPoseParameter(self.formTable.aim.yPose, pitch)
                            end
                        end

                        if not ply:IsOnGround() and not self.touchingWater and ply:WaterLevel() > 0 and self.formTable.land then
                            self.formTable.land(ply, self)
                        end

                        --tick attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
                            self.formTable.attack.func(ply, self, self.formTable.attack)
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
                            self.formTable.attack2.func(ply, self, self.formTable.attack2)
                        end

                        --auto attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack")
                            else
                                self:PillLoopStop("attack")
                            end

                            if (not self.lastAttack or (self.formTable.attack.interval or self.formTable.attack.delay) < CurTime() - self.lastAttack) then
                                self.formTable.attack.func(ply, self, self.formTable.attack)
                                self.lastAttack = CurTime()
                            end
                        else
                            self:PillLoopStop("attack")
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack2")
                            else
                                self:PillLoopStop("attack2")
                            end

                            if not self.lastAttack2 or (self.formTable.attack2.interval or self.formTable.attack2.delay) < CurTime() - self.lastAttack2 then
                                self.formTable.attack2.func(ply, self, self.formTable.attack2)
                                self.lastAttack2 = CurTime()
                            end
                        else
                            self:PillLoopStop("attack2")
                        end

                        --if !IsValid(ply) then self:NextThink(CurTime()) return true end
                        --wepon-no longer SO hackey
                        if not self.formTable.hideWeapons then
                            local realWep = self:GetPillUser():GetActiveWeapon()

                            --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
                            if IsValid(realWep) and realWep:GetModel() ~= "" then
                                --hiding the real thing [BROKEN]
                                --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                                    realWep:SetRenderMode(RENDERMODE_NONE)
                                end]]
                                if realWep.pill_attachment then
                                    if IsValid(self.wepmdl) then
                                        self.wepmdl:Remove()
                                    end

                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl.attachment = realWep.pill_attachment
                                    self.wepmdl:Spawn()

                                    if realWep.pill_offset then
                                        self.wepmdl:SetWepOffset(realWep.pill_offset)
                                    end

                                    if realWep.pill_angle then
                                        self.wepmdl:SetWepAng(realWep.pill_angle)
                                    end

                                    realWep.pill_proxy = self.wepmdl
                                elseif not IsValid(self.wepmdl) then
                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl:Spawn()
                                    realWep.pill_proxy = self.wepmdl
                                elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                                    self.wepmdl:SetModel(realWep:GetModel())
                                end
                            elseif IsValid(self.wepmdl) then
                                self.wepmdl:Remove()
                            end
                        end
                    else
                        if self:GetPillUser() ~= LocalPlayer() or pk_pills.convars.cl_thirdperson:GetBool() then
                            puppet:SetNoDraw(false)
                        else
                            puppet:SetNoDraw(true)
                        end

                        local realWep = self:GetPillUser():GetActiveWeapon()

                        if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                            realWep:SetNoDraw(true)
                        end
                    end

                    --Align pos and angles with player
                    if SERVER then
                        puppet:SetPos(ply:GetPos())
                    else
                        puppet:SetRenderOrigin(ply:GetPos())
						
						local talkie = self.formTable.talk
						if talkie and talkie.jawbone then
							local jawAngle = Angle(0,0,0)
							local weight = ply:IsSpeaking() and math.Clamp(ply:VoiceVolume() * 2, 0, 2) or 0
							
							local mp = 1
							local boneID = puppet:LookupBone(talkie.jawbone)
							local scale = talkie.scale or 1
							if talkie.reversed then mp = -1 end
							
							if boneID then
								jawAngle.r = -weight * (25 * scale) * mp
								local angle = ply:IsSpeaking() and jawAngle or angle_zero
								puppet:ManipulateBoneAngles(boneID, angle)
							end
						end
                    end
                    
                    currentanim = self:GetNWString("Animlastplayed")

                    --if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 then

                    local animsshouldspn = table.Copy(self.formTable.anims.ShouldMoveRotate or {})
                    if animsshouldspn[currentanim] or (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) then
                        
                        local typeofitem = (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) or animsshouldspn[currentanim]
                        local function SetTargetAngle(ang)
                            ang.p = 0
                            puppet:SetNW2Vector("SyncAng", ang:Forward())
                        end

                        local function GetTargetAngle()
                            local dir = puppet:GetNW2Vector("SyncAng")
                            if not dir or dir == vector_origin then return nil end
                            local ang = dir:Angle()
                            if not ang then return nil end
                            ang.p = 0
                            return ang
                        end

                        if typeofitem == "notshftlock" then
                            local dir = ply:GetVelocity():GetNormalized()
                            local aheadPos = ply:GetPos() + dir * 5
                            local ang = (aheadPos - ply:GetPos()):Angle()
                            ang.p = 0
                            if ply:GetVelocity().x == 0 and ply:GetVelocity().y == 0 then
                            else
                                if SERVER then
                                    SetTargetAngle(ang)
                                    puppet:SetAngles(ang)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end
                            end

                        elseif typeofitem == "assignedagnles_instant" then
                            local targetAng = self:GetNWAngle("pill_assignedangle")

                            if SERVER then
                                SetTargetAngle(targetAng)
                                puppet:SetAngles(targetAng)
                            end

                            if CLIENT then
                                if targetAng then
                                    puppet:SetRenderAngles(targetAng)
                                end
                            end

                        elseif typeofitem == "shiftlock" then
                            local angs = ply:EyeAngles()
                            angs.p = 0

                            if SERVER then
                                SetTargetAngle(angs)
                                puppet:SetAngles(angs)
                            end

                            if CLIENT then
                                local targetAng = GetTargetAngle()
                                if targetAng then
                                    local curAng = puppet:GetRenderAngles()
                                    if not curAng then curAng = targetAng end
                                    if not curAng.p then curAng = Angle(0,0,0) end
                                    local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                    puppet:SetRenderAngles(smoothAng)
                                end
                            end

                        elseif typeofitem == "Playerangles" then
                            local angs = ply:GetAngles()
                            angs.p = 0

                            if SERVER then
                                SetTargetAngle(angs)
                                puppet:SetAngles(angs)
                            end

                            if CLIENT then
                                local targetAng = GetTargetAngle()
                                if targetAng then
                                    local curAng = puppet:GetRenderAngles()
                                    if not curAng then curAng = targetAng end
                                    if not curAng.p then curAng = Angle(0,0,0) end
                                    local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                    puppet:SetRenderAngles(smoothAng)
                                end
                            end

                        elseif typeofitem == "assignedagnles" then
                            local targetAng = self:GetNWAngle("pill_assignedangle")

                            if SERVER then
                                SetTargetAngle(targetAng)
                                puppet:SetAngles(targetAng)
                            end

                            if CLIENT then
                                if targetAng then
                                    local curAng = puppet:GetRenderAngles()
                                    if not curAng then curAng = targetAng end
                                    if not curAng.p then curAng = Angle(0,0,0) end
                                    local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                    puppet:SetRenderAngles(smoothAng)
                                end
                            end

                        elseif typeofitem == "notanything" then
                        end
                    end

                    if self.formTable.think_n_bon_withered then
                        self.formTable.think_n_bon_withered(ply, ent)
                    end
                    self:NextThink(CurTime())

                    return true
                end
            end
            if ent.formTable.HandleAnimEvent_gen_bon then

                function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                    return true
                end
                function PuppetEntity:HandleAnimEvent(event, eventTime, cycle, eventType, options)
                    ent.formTable.HandleAnimEvent_gen_bon(entityply, ent, options)
                    return true
                end
            end
        end
    end)
end)

if SERVER then
    util.AddNetworkString('bon_jumpscare_gen_withered')
    util.AddNetworkString("bon_jumpscare_cleanup_withered")
    util.AddNetworkString("bon_emergency_cleanup_withered")

    util.AddNetworkString("Gentoi_bon_CameraCode_n_withered")

else

    net.Receive("Gentoi_bon_CameraCode_n_withered", function()
        local ply = LocalPlayer()
        local ent = net.ReadEntity()

        timer.Simple(0,function()
            if !IsValid(ent) then return end

            local savedCalcViewHooks = {}

            local calcViewHooks = hook.GetTable().CalcView or {}
            for k, v in pairs(calcViewHooks) do
                if k ~= hookID then
                    savedCalcViewHooks[k] = v
                    hook.Remove("CalcView", k)
                end
            end

            local name6 = "momo_calcview_".. ply:Nick()
            local name5 = "gentoi_remove_n_".. ply:Nick()
            hook.Add("EntityRemoved", name5, function(removedent)
                if removedent == ent then
                    hook.Remove('CalcView', name6)
                    hook.Remove("EntityRemoved", name5)
                    for savedID, func in pairs(savedCalcViewHooks) do
                        hook.Add("CalcView", savedID, func)
                    end
                    savedCalcViewHooks = {}
                end
            end)
            
            local lastID = nil
            local lastOrigin = nil
            local lastFOV = nil
            local transitionStart = 0
            local transitionTime = 0.25

            hook.Add("CalcView", name6, function(ply, pos, ang, fov)
                local ent = pk_pills.getMappedEnt(ply)
                if not IsValid(ent) or ply:GetViewEntity() ~= ply then return end

                local currentOMTable = ent.formTable.OM_cameratable(ply, ent)
                if not currentOMTable then return end

                if lastID ~= currentOMTable.id then
                    lastID = currentOMTable.id
                    transitionStart = CurTime()
                    lastOrigin = lastOrigin or pos
                    lastFOV = lastFOV or fov
                end

                if transitionTime ~= currentOMTable.transition then
                    transitionTime = currentOMTable.transition
                end

                local up = ang:Up() * currentOMTable.startoffset.z
                local right = ang:Right() * currentOMTable.startoffset.x
                local forward = ang:Forward() * currentOMTable.startoffset.y
                local startpos = ply:GetPos() + up + right + forward
                if currentOMTable.bonecenter then
                    local boneID = ent:GetPuppet():LookupBone(currentOMTable.bonecenter)
                    local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)
                    startpos = bonePos + up + right + forward
                end

                if pk_pills.convars.cl_thirdperson:GetBool() then
                    local dist = currentOMTable.dist
                    local offset = ang:Forward() * -dist

                    local tr = util.TraceHull({
                        start = startpos,
                        endpos = startpos + offset,
                        filter = ent.camTraceFilter,
                        mins = Vector(-5, -5, -5),
                        maxs = Vector(5, 5, 5),
                        mask = MASK_VISIBLE
                    })

                    local targetOrigin = tr.HitPos
                    local targetFOV = currentOMTable.fov

                    local t = math.Clamp((CurTime() - transitionStart) / transitionTime, 0, 1)

                    local smoothOrigin = LerpVector(t, lastOrigin, targetOrigin)
                    local smoothFOV = Lerp(t, lastFOV, targetFOV)

                    lastOrigin = smoothOrigin
                    lastFOV = smoothFOV

                    return {
                        origin = smoothOrigin,
                        angles = ang,
                        fov = smoothFOV,
                        drawviewer = true
                    }
                end
            end)
        end)
    end)

    -- Enhanced CLIENT-SIDE jumpscare with neck-breaking effects
    net.Receive('bon_jumpscare_gen_withered', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "sbon_jumpscare_gen_" .. LocalPlayer():SteamID()
        local effectsHookID = "sbon_jumpscare_effects_" .. LocalPlayer():SteamID()

        hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
            if not IsValid(ply) or not ply:Alive() or not IsValid(ent) or not state then
                hook.Remove('CalcView', hookID)
                hook.Remove('RenderScreenspaceEffects', effectsHookID)
                if IsValid(ply) then
                    ply:RemoveFlags(FL_NOTARGET)
                    ply:Freeze(false)
                    ply:DrawViewModel(true)
                end
                return
            end

            local cam = ent:GetAttachment(ent:LookupAttachment('camera'))
            if not cam then 
                hook.Remove('CalcView', hookID) 
                hook.Remove('RenderScreenspaceEffects', effectsHookID)
                return 
            end

            ply:AddFlags(FL_NOTARGET)
            ply:Freeze(true)
            ply:DrawViewModel(false)

            local lerpFactor = math.Clamp((CurTime() - startTime) / 0.7, 0, 1)
            
            local targetFOV = 60 

            local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos)
            local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
            local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)

            local dl = DynamicLight(ply:EntIndex())
            if dl then
                dl.pos = cam.Pos
                dl.r = 255
                dl.g = 255
                dl.b = 255
                dl.brightness = 0.5
                dl.Decay = 1000
                dl.Size = 125
                dl.DieTime = CurTime() + 0.1
            end

            local view = {
                origin = orgiginlerpto,
                angles = angleslerpto,
                fov = fov,
                drawviewer = false
            }
            return view
        end)
    end)

    -- Cleanup functions for proper effect removal
    net.Receive("bon_jumpscare_cleanup_withered", function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        
        local hookID = "sbon_jumpscare_gen_" .. LocalPlayer():SteamID()
        local effectsHookID = "sbon_jumpscare_effects_" .. LocalPlayer():SteamID()
        
        hook.Remove("CalcView", hookID)
        hook.Remove("RenderScreenspaceEffects", effectsHookID)
        
        local ply = LocalPlayer()
        if IsValid(ply) then
            ply:RemoveFlags(FL_NOTARGET)
            ply:DrawViewModel(true)
        end
        
        --print("[BON PILL DEBUG CLIENT] Jumpscare cleaned up")
    end)

    net.Receive("bon_emergency_cleanup_withered", function()
        local ent = net.ReadEntity()
        
        local ply = LocalPlayer()
        local hookID = "sbon_jumpscare_gen_" .. ply:SteamID()
        local effectsHookID = "sbon_jumpscare_effects_" .. ply:SteamID()
        
        hook.Remove("CalcView", hookID)
        hook.Remove("RenderScreenspaceEffects", effectsHookID)
        
        if IsValid(ply) then
            ply:RemoveFlags(FL_NOTARGET)
            ply:DrawViewModel(true)
        end
        
        --print("[BON PILL DEBUG CLIENT] Emergency cleanup completed")
    end)
end

local function AdvancedPillSound(SoundData, ent)
    if IsValid(ent) then
        SoundData = SoundData or {}
        SoundData.stringe = SoundData.stringe or {}
        SoundData.soundLevel = SoundData.soundLevel or 75
        SoundData.pitchPercent = SoundData.pitchPercent or 100
        SoundData.volume = SoundData.volume or 1
        SoundData.channel = SoundData.channel or CHAN_AUTO
        SoundData.soundFlags = SoundData.soundFlags or 0
        SoundData.dsp = SoundData.dsp or 0
        SoundData.filter = SoundData.filter or nil

        local chosenSound = SoundData.stringe

        if istable(SoundData.stringe) then
            local index = math.random(1, #SoundData.stringe)
            chosenSound = SoundData.stringe[index]
        end

        ent:EmitSound(
            chosenSound,
            SoundData.soundLevel,
            SoundData.pitchPercent,
            SoundData.volume,
            SoundData.channel,
            SoundData.soundFlags,
            SoundData.dsp,
            SoundData.filter
        )
    end
    return true
end

local function BonCvar(name, default)
    local cv = GetConVar(name)
    if cv then return cv:GetFloat() end

    return default
end

local jumpscareVoiceLines = {
    "gentoi/witheredbon/WITHEREDBONVOICELINE1.wav",
    "gentoi/witheredbon/WITHEREDBONVOICELINE2.wav",
    "gentoi/witheredbon/WITHEREDBONVOICELINE3.wav",
    "gentoi/witheredbon/WITHEREDBONVOICELINE4.wav"
}

local tauntSounds = {
    "dark/bon/BONsound1.mp3",
    "dark/bon/BONsound2.mp3",
    "gentoi/witheredbon/BonLaughNew.wav"
}

-- Players que a Kill API aceita como alvo dentro de uma esfera
local function BonFindTargets(ply, pos, radius, ignoreNoTarget)
    local found = {}

    for _, v in ipairs(ents.FindInSphere(pos, radius)) do
        if not v:IsPlayer() or v == ply then continue end
        if not SherlockHNS.CanTarget(v, ply) then continue end
        if ignoreNoTarget and bit.band(v:GetFlags(), FL_NOTARGET) ~= 0 then continue end
        found[#found + 1] = v
    end

    return found
end

-- Visual do jumpscare (esqueleto + corpo da vitima). Retorna a funcao de limpeza
-- que o playHNSJumpscare chama quando o kill termina ou e cancelado.
local function BonJumpscareVisuals(ply, ent, victim)
    local puppet = ent:GetPuppet()

    local ang = (ply:GetPos() - victim:GetPos()):Angle()
    ang.p = 0
    ang.r = 0
    victim:SetEyeAngles(ang)

    local anim, fake
    local hidden = false
    local oldColor, oldRender

    if victim:LookupBone("ValveBiped.Bip01_Pelvis") then
        anim = ents.Create("prop_dynamic")
        anim:SetModel("models/Gentoi/walterfiles/bon/killanim.mdl")
        anim:SetPos(puppet:GetPos() + puppet:GetForward() * 3 + puppet:GetUp() * 5)
        anim:SetAngles(puppet:GetAngles() + Angle(0, 180, 0))
        anim:SetParent(puppet)
        anim:Spawn()
        ent:DeleteOnRemove(anim)
        anim:ResetSequence("skeleton")

        fake = ents.Create("prop_dynamic")
        fake:SetModel(victim:GetModel())
        fake:SetParent(anim)
        fake:AddEffects(EF_BONEMERGE)
        fake:Fire("SetParentAttachment", "camera")
        fake:Spawn()
        ent:DeleteOnRemove(fake)
        ent:SetNWEntity("JumpscareDeathThing_ent", fake)
        fake:SetNWEntity("JumpscareDeathThing_ent_scp096", victim)

        oldColor = victim:GetColor()
        oldRender = victim:GetRenderMode()
        victim:SetRenderMode(RENDERMODE_TRANSCOLOR)
        victim:SetColor(Color(255, 255, 255, 0))
        victim:SetNoDraw(true)
        victim:SetActiveWeapon(NULL)
        hidden = true
    end

    return function()
        local rag

        if IsValid(anim) and IsValid(fake) then
            anim:SetParent(NULL)
            local a = fake:GetAngles()
            a:RotateAroundAxis(anim:GetForward(), 90)
            a:RotateAroundAxis(anim:GetUp(), 90)
            local fwd = IsValid(puppet) and puppet:GetForward() or anim:GetForward()
            rag = {
                model = fake:GetModel(),
                pos = anim:GetPos() + fwd * 30,
                ang = a + Angle(0, 180, 0)
            }
        end

        if IsValid(anim) then anim:Remove() end
        if IsValid(fake) then fake:Remove() end
        if IsValid(ent) then ent:SetNWEntity("JumpscareDeathThing_ent", NULL) end

        if hidden and IsValid(victim) then
            victim:SetNoDraw(false)
            victim:SetRenderMode(oldRender)
            victim:SetColor(oldColor)
        end

        -- So comemora se a vitima realmente morreu (force field/infeccao/cancelamento nao contam)
        timer.Simple(0.1, function()
            if not IsValid(victim) or victim:Alive() then return end

            if rag then
                local r = ents.Create("prop_ragdoll")
                r:SetModel(rag.model)
                r:SetPos(rag.pos)
                r:SetAngles(rag.ang)
                r:Spawn()
            end

            if IsValid(ent) then
                AdvancedPillSound({
                    stringe = jumpscareVoiceLines,
                    pitchPercent = 100,
                    soundLevel = 67
                }, ent)
            end
        end)
    end
end

-- Kill via Kill API: playHNSJumpscare -> SherlockHNS.KillWithDelay.
-- O gamemode cuida de travas, alvo valido, cancelamento, force field e morte.
local function BonStartJumpscare(ply, ent)
    if not SherlockHNS or not pk_pills.playHNSJumpscare then return false end

    local puppet = ent:GetPuppet()
    if not IsValid(puppet) then return false end

    local victim, nearest

    for _, v in ipairs(BonFindTargets(ply, ent:LocalToWorld(Vector(0, 0, 50)), 70, false)) do
        local d = v:GetPos():DistToSqr(ply:GetPos())

        if not nearest or d < nearest then
            victim, nearest = v, d
        end
    end

    if not victim then return false end

    local dur = puppet:SequenceDuration(puppet:LookupSequence("kill"))

    local started = pk_pills.playHNSJumpscare(ply, ent, victim, dur, {
        camera = "bon_jumpscare_gen_withered",
        offset = 75,
        animation = "jumpscare",
        sound = "jumpscares",
        onStart = function(v)
            return BonJumpscareVisuals(ply, ent, v)
        end,
    })

    return started and true or false
end

-- Habilidades da pill (Abilities API). hnsAbilities em forma de funcao: as
-- convars de admin sao lidas na hora em que a pill e concedida.
local function BonBuildAbilities(ply, ent)
    local list = {}

    list[#list + 1] = {
        id = "jumpscare",
        name = "Jumpscare",
        icon = "gentoi/witheredbon/bon_char1.png",
        key = IN_ATTACK,
        color = Color(255, 40, 40),
        cooldown = 0,
        order = 1,

        CanUse = function(p, e)
            if not IsValid(e) then return false end
            if IsValid(e.Ragdollentity) then return false end
            if e:GetNW2Float("jup_delyay_bon") >= CurTime() then return false end
            if e:GetNW2Float("trueform_duration") > CurTime() then return false end
            if p:GetNWInt("DisableMovement_jumpscare_pill_bon_withered") >= CurTime() then return false end
        end,

        -- retorna false se nao houver alvo, para nao gastar cooldown
        OnUse = function(p, e)
            return BonStartJumpscare(p, e)
        end,
    }

    if BonCvar("GentoiPills_bon_canuse_trueform", 1) ~= 0 then
        list[#list + 1] = {
            id = "trueform",
            name = "Forma Verdadeira",
            icon = "gentoi/witheredbon/trueformicon1.png",
            keyLabel = "1",
            color = Color(255, 60, 60),
            toggle = true,
            duration = BonCvar("GentoiPills_bon_canuse_trueform_duration", 20),
            cooldown = BonCvar("GentoiPills_bon_canuse_trueform_cd_failed", 15),
            tickInterval = 0.05,
            order = 2,

            CanUse = function(p, e, ab)
                if ab.active then return end -- desligar sempre pode
                if not IsValid(e) or not IsValid(e:GetPuppet()) then return false end
                if BonCvar("GentoiPills_bon_canuse_trueform", 1) == 0 then return false end
                if IsValid(e.Ragdollentity) then return false end
                if p:GetNWInt("DisableMovement_jumpscare_pill_bon_withered") >= CurTime() then return false end
            end,

            OnUse = function(p, e, ab)
                local puppet = IsValid(e) and e:GetPuppet()
                if not IsValid(puppet) then return false end

                local decoy = ents.Create("prop_dynamic")
                decoy:SetModel("models/gentoi/walterfiles/witheredbon.mdl")
                decoy:Spawn()
                decoy:SetPos(puppet:GetPos())
                decoy:SetAngles(puppet:GetAngles())
                e:DeleteOnRemove(decoy)

                decoy:ResetSequence(decoy:LookupSequence("idle"))
                decoy:SetCycle(0)
                decoy:SetPlaybackRate(1)

                ab.data.decoy = decoy
                ab.data.decoyPos = puppet:GetPos()
                ab.data.hit = nil

                e.FakePuppet_witheredbon_gentoi = decoy
                e:SetNWBool("FakePuppet_witheredbon_gentoi", true)
                e:SetNW2Float("trueform_duration", CurTime() + (ab.def.duration or 0))
            end,

            -- Corpo antigo: realca inimigos perto dele; se Bon encosta num inimigo, encerra com "hit"
            OnTick = function(p, e, ab)
                if not IsValid(e) then return end

                local data = ab.data
                local decoy = data.decoy

                if not IsValid(decoy) then
                    SherlockHNS.Ability.End(p, "trueform", "manual")

                    return
                end

                local now = CurTime()
                local puppet = e:GetPuppet()

                if IsValid(puppet) then
                    puppet:SetNW2Float("witheredbon_2ddisplay_gentoi", now + 0.25)
                end

                if p:GetPos():Distance(decoy:GetPos()) > 1100 then
                    local range = BonCvar("GentoiPills_bon_canuse_trueform_oldbody_detectionrange", 500)

                    for _, v in ipairs(BonFindTargets(p, decoy:GetPos(), range, true)) do
                        v:SetNW2Float("outline_witheredbon_gentoi_distance", now + 0.25)
                    end
                end

                local caught = BonFindTargets(p, e:LocalToWorld(Vector(0, 0, 50)), 120, true)
                if #caught == 0 then return end

                local outline = BonCvar("GentoiPills_bon_canuse_trueform_outlineduration", 20)

                for _, v in ipairs(caught) do
                    v:SetNW2Float("outline_witheredbon_gentoi", now + outline)
                    e.CaughtEnemy_gentoi_bon = v

                    net.Start("OM_gentoi_witheredbon_PlayGlobalSound")
                    net.Send(v)
                    net.Start("gentoi_bon_2djumpscare")
                    net.Send(v)
                end

                data.hit = true
                SherlockHNS.Ability.End(p, "trueform", "manual")
            end,

            OnEnd = function(p, e, ab, reason)
                local data = ab.data
                local pos = data.decoyPos
                local hit = data.hit

                if IsValid(data.decoy) then data.decoy:Remove() end
                data.decoy = nil
                data.decoyPos = nil
                data.hit = nil

                if IsValid(e) then
                    e.FakePuppet_witheredbon_gentoi = nil
                    e:SetNWBool("FakePuppet_witheredbon_gentoi", false)
                    e:SetNW2Float("trueform_duration", 0)

                    local puppet = e:GetPuppet()

                    if IsValid(puppet) then
                        puppet:SetNW2Float("witheredbon_2ddisplay_gentoi", 0)
                    end

                    if hit then
                        e:SetNW2Float("Bon_ability_nosound", CurTime() + BonCvar("GentoiPills_bon_canuse_trueform_nosoundduration", 20))
                        e:SetNW2Float("jup_delyay_bon", CurTime() + 0.75)
                    end
                end

                -- morte, troca de rodada, troca de pill e saida: o gamemode limpa sozinho
                if reason ~= "expired" and reason ~= "toggle" and reason ~= "manual" then return end
                if not IsValid(p) or not p:Alive() then return end

                if pos then p:SetPos(pos) end

                -- cooldown diferente para acerto e para falha (apos a API iniciar o dela)
                local cd = hit and BonCvar("GentoiPills_bon_canuse_trueform_cd_hit", 25)
                    or BonCvar("GentoiPills_bon_canuse_trueform_cd_failed", 15)

                timer.Simple(0, function()
                    if IsValid(p) and SherlockHNS then
                        SherlockHNS.Ability.SetCooldown(p, "trueform", cd)
                    end
                end)
            end,
        }
    end

    list[#list + 1] = {
        id = "voice",
        name = "Voz",
        keyLabel = "T",
        color = Color(200, 200, 200),
        cooldown = 1,
        anyRound = true,
        order = 3,

        OnUse = function(p, e)
            if not IsValid(e) then return false end

            local snd = tauntSounds[math.random(#tauntSounds)]
            local duration = SoundDuration(snd)
            if not duration or duration <= 0 then duration = 2 end

            AdvancedPillSound({ stringe = snd }, e)

            -- o cooldown dura o tamanho do som (como era o VoiceLineDelay)
            timer.Simple(0, function()
                if IsValid(p) and SherlockHNS then
                    SherlockHNS.Ability.SetCooldown(p, "voice", duration)
                end
            end)
        end,
    }

    return list
end

hook.Add("SetupMove", "DisablePlayerMovement_bon_withered", function(ply, mv, cmd)
    if ply:GetNWInt("DisableMovement_jumpscare_pill_bon_withered") >= CurTime() then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end
end)

if SERVER then
    util.AddNetworkString("OM_gentoi_witheredbon_PlayGlobalSound")
end

if CLIENT then


    net.Receive("OM_gentoi_witheredbon_PlayGlobalSound", function()
        surface.PlaySound("gentoi/witheredbon/pingsound.wav")
    end)


    local entities = {}

    hook.Add("NetworkEntityCreated", "witheredbon_optimized_init", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end

            if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then else return end

            entities[ent] = true

            --print("Added render entity:", ent, class, model)
        end)
    end)

    hook.Add("EntityRemoved", "witheredbon_optimized_remove", function(ent)
        if entities[ent] then
            entities[ent] = nil
            --print("Removed render entity:", ent)
        end
    end)

    hook.Add("PostDrawTranslucentRenderables", "witheredbon_2ddisplay_gentoi", function(bDrawingDepth, bDrawingSkybox)
        local ply = LocalPlayer()
        if !IsValid(ply) then return end

        for _, v in ipairs(ents.FindByModel("models/gentoi/walterfiles/witheredbon.mdl")) do
            if !IsValid(v) then continue end
            if v:GetNoDraw() then continue end
            
            if v:GetNW2Float("witheredbon_2ddisplay_gentoi") >= CurTime() then
                local pos = v:GetRenderOrigin() + Vector(0, 0, 40)

                local ang = EyeAngles()
                ang:RotateAroundAxis(ang:Up(), -90)
                ang:RotateAroundAxis(ang:Forward(), 90)

                cam.Start3D2D(pos, ang, 0.1)
                    surface.SetMaterial(Material("gentoi/witheredbon/Full_Body_Bon_Infobox.png"))

                    local size = 1000

                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.DrawTexturedRect(0-size*0.5/3, -size*0.85, size*0.5, size+300)
                cam.End3D2D()
            end
        end

        for v, _ in pairs(entities) do
            local mat = Material("models/debug/debugwhite")

            local function DrawOutline(ent)
                local rag = ent:GetNWEntity("OM_ragdollentity")

                if IsValid(rag) then
                    ent = rag
                end

                if ent.pk_pill_ent then
                    if ent.pk_pill_ent.GetPuppet then
                        ent = ent.pk_pill_ent:GetPuppet()
                    else
                        ent = ent.pk_pill_ent
                    end
                end

                if not IsValid(ent) then return end

                render.MaterialOverride(mat)
                render.SuppressEngineLighting(true)
                render.SetColorModulation(1, 1, 1)
                render.SetBlend(0.5)

                cam.IgnoreZ(true)
                ent:DrawModel()
                cam.IgnoreZ(false)

                render.SetBlend(1)
                render.SuppressEngineLighting(false)
                render.MaterialOverride(nil)
            end

            local ct = CurTime()

            if v:GetNW2Float("outline_witheredbon_gentoi_distance", 0) >= ct then
                DrawOutline(v)
            end

            if v:GetNW2Float("outline_witheredbon_gentoi", 0) >= ct then
                DrawOutline(v)
            end
        end
    end)
end

local walkFootsteps = {"gentoi/witheredbon/Bon walk step 1.mp3", "gentoi/witheredbon/Bon walk step 2.mp3", "gentoi/witheredbon/Bon walk step 3.mp3"}
local runFootsteps = {"gentoi/witheredbon/Bon run step 1.mp3","gentoi/witheredbon/Bon run step 2.mp3","gentoi/witheredbon/Bon run step 3.mp3"}


pk_pills.packStart("Walten files 2", "PIll_bon_ds_withered", "pills/WITHEREDBONWORKSHOPICON.png")

pk_pills.register('PIll_bon_ds_withered', {

    printName='bon _withered',
        
    model="models/gentoi/walterfiles/witheredbon.mdl",
        
    noragdoll = true,
    muteSteps = true,
    specialthinkcode = true,
    _bon_pill_ds_withered = "IT\'S BONNET",
        
    anims={
        default={
            idle="idle",
            run="run",
            walk="walk",
            jumpscare="kill",
            crouch = "Crouch",
            crouch_walk = "CrawlMovement",
            spawn = "spawn"
        },
        ShouldMoveRotate={
            idle= function(ent) 
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            Crouch= function(ent) 
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            CrawlMovement= function(ent)
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
            run= function(ent)
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
            spawn= function(ent)
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
            walk= function(ent)
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
        },

        ShouldAlternate={
        },
    },
        

    OM_cameratable = function(ply,ent)
        local basetable =  {
            startoffset = Vector(35,0,15),  -- left-up, front-back, up-down
            dist=100,
            fov = 80,
            id = 0,
            transition = 1,
            bonecenter = "UpperTorso",
        }
        if ent:GetNWBool("FakePuppet_witheredbon_gentoi") then
            basetable =  {
                startoffset = Vector(50,0,80),  -- left-up, front-back, up-down
                dist=135,
                fov = 80,
                id = 1,
                transition = 1,
            }
        end
        return basetable
    end,
        
    sounds={
        jumpscares = "gentoi/witheredbon/WITHEREDBONKILLSFX.wav"
    },
	
	talk = {
		jawbone="Jaw",
		reversed=false,
		scale=1.2,
	},

    type='ply',

    camera={
        offset = Vector(0, 0, 75),
        dist=135,
    },
        
    health=2000,
    
    movePoseMode="xy",
    aim={
        xPose="aim_yaw",
        yPose="aim_pitch",
        nocrosshair = true
    },
        
    canAim=function(ply,ent) return ent.active end,    

    HandleAnimEvent_gen_bon = function(ply, ent, event)
        if event == "bloodsplatter" then
            local bone = ent:GetPuppet():LookupBone("Hand.L")
            if bone then
                local pos, ang = ent:GetPuppet():GetBonePosition(bone)

                pos = pos + ang:Right()*-5
                pos = pos + ang:Forward()*4
                
                local effectdata = EffectData()
                effectdata:SetOrigin(pos)
                effectdata:SetNormal(ang:Forward())

                effectdata:SetMagnitude(3)
                effectdata:SetScale(10)
                effectdata:SetColor(0)
                effectdata:SetFlags(3)
                util.Effect("bloodspray", effectdata)

                local effectdata = EffectData()
                effectdata:SetOrigin(pos)
                effectdata:SetNormal(ang:Forward())

                effectdata:SetMagnitude(3)
                effectdata:SetScale(10)
                effectdata:SetColor(0)
                effectdata:SetFlags(3)
                util.Effect("bloodspray", effectdata)
            end
        end
        if event == "HeartCreate" then
            local bone = ent:GetPuppet():LookupBone("Hand.L")
            if bone then
                local pos, ang = ent:GetPuppet():GetBonePosition(bone)

                pos = pos + ang:Right()*-5
                pos = pos + ang:Forward()*4
                
                local effectdata = EffectData()
                effectdata:SetOrigin(pos)
                effectdata:SetNormal(ang:Forward())

                effectdata:SetMagnitude(3)
                effectdata:SetScale(10)
                effectdata:SetColor(0)
                effectdata:SetFlags(3)
                util.Effect("bloodspray", effectdata)

                local effectdata = EffectData()
                effectdata:SetOrigin(pos)
                effectdata:SetNormal(ang:Forward())

                effectdata:SetMagnitude(3)
                effectdata:SetScale(10)
                effectdata:SetColor(0)
                effectdata:SetFlags(3)
                util.Effect("bloodspray", effectdata)
            end
            ent:GetPuppet():SetBodygroup(3, 1)
        end
        if event == "HeartPop" then
            local bone = ent:GetPuppet():LookupBone("Hand.L")
            if bone then
                local pos, ang = ent:GetPuppet():GetBonePosition(bone)

                pos = pos + ang:Right()*-5
                pos = pos + ang:Forward()*4
                
                local effectdata = EffectData()
                effectdata:SetOrigin(pos)
                effectdata:SetNormal(ang:Forward())

                effectdata:SetMagnitude(3)
                effectdata:SetScale(30)
                effectdata:SetColor(0)
                effectdata:SetFlags(3)
                util.Effect("bloodspray", effectdata)
            end
            ent:GetPuppet():SetBodygroup(3, 0)
        end
        if event == "Step" then
            if ent:GetNW2Float("Bon_ability_nosound") >= CurTime() then return end
            if ent:GetNW2Float("trueform_duration") >= CurTime() then return end
            if ent.FakePuppet_witheredbon_gentoi and IsValid(ent.FakePuppet_witheredbon_gentoi) then return end
            if IsValid(ent) then
                if ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) == "walk" or ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) ==  "CrawlMovement" then
                    AdvancedPillSound({
                        stringe = walkFootsteps,
                        pitchPercent = 100,
                        soundLevel = 67
                    }, ent)
                elseif ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) == "run" then
                    AdvancedPillSound({
                        stringe = runFootsteps,
                        pitchPercent = 100,
                        soundLevel = 67
                    }, ent)
                end
            end
        end
    end,

    -- Sherlock HnS: ataque (M1), Forma Verdadeira (1) e voz (T) estao na Abilities API
    -- (BonBuildAbilities). O kill passa pela Kill API (playHNSJumpscare -> KillWithDelay).
    -- A pill nao fere players por conta propria, entao a auditoria e declarada explicitamente.
    hnsKillAPI = true,
    hnsAbilities = BonBuildAbilities,

    flashlight = function(ply, ent)


    end,

    deactivateKeybind_noodles_bon = function(ply,ent,button)
        if SERVER then
            if button == KEY_SLASH then
                ent:SetNWBool('HoldingDownMenu_bon', false)
                --ent:SetNW2Float("rat_opponent_gentoi", ply)
                ent:SetNW2Float('HoldingDownMenu_rat_timeframe', CurTime())
            end
            if button == KEY_SPACE then
                ent:SetNW2Bool('HoldingDownMenu_space_bon', false)
            end
        end
    end,

    ActivateKeybind_noodles_bon = function(ply, ent, button)
        if button == KEY_SLASH then
            ent:SetNWBool('HoldingDownMenu_bon', true)
            ent:SetNW2Float('HoldingDownMenu_rat_timeframe', CurTime())
            --ent:SetNW2Float("rat_opponent_gentoi", ply)
        end
        if button == KEY_SPACE then
            ent:SetNW2Bool('HoldingDownMenu_space_bon', true)
        end
        if button == KEY_1 then
            -- Forma Verdadeira: regras de uso, duracao e cooldown ficam na Ability API
            if SERVER and SherlockHNS then
                SherlockHNS.Ability.Use(ply, "trueform")
            end
        end
        if button == KEY_R then
            if ent:GetNWBool("Shiftlock") then
                ent:SetNWBool("Shiftlock", false)
            else
                ent:SetNWBool("Shiftlock", true)
            end
        end
        if button == KEY_T then
            if SERVER and SherlockHNS then
                SherlockHNS.Ability.Use(ply, "voice")
            end
        end
    end,

    jump = function(ply, ent) end,

    -- Velocidade definida somente pelo Parakeet's (pk_pills.getMoveSpeed / ApplyMoveSpeed)
    moveSpeed = {
        walk = 64,
        run = 420,
        ducked = 64,
    },
    jumpPower = 0,

    think_n_bon_withered = function(ply, ent)
        if SERVER then
            if not ent.SpawnInEntSpawnAnim then
                ent.SpawnInEntSpawnAnim = true
                if GetConVar("GentoiPills_bon_hasintroanim"):GetBool() then
                    local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("spawn"))
                    ply:SetNWInt("DisableMovement_jumpscare_pill_bon_withered", dur+CurTime())
                    ent:PillAnim("spawn")
                end
            end
            
            local puppet = ent:GetPuppet()
            puppet:SetRenderMode(RENDERMODE_TRANSALPHA)

            -- A habilidade "trueform" (Abilities API) cuida de duracao, deteccao e cooldown.
            -- Aqui so mantemos o corpo real invisivel enquanto o corpo antigo existe.
            if IsValid(ent.FakePuppet_witheredbon_gentoi) then
                puppet:SetColor(Color(255,255,255,0))
                puppet:DrawShadow(false)
            else
                puppet:DrawShadow(true)
                puppet:SetColor(Color(255,255,255,255))
            end

            if ent:GetNW2Float("Bon_ability_nosound") >= CurTime() then
                if not ent.Bon_ability_nosound then
                    ent.Bon_ability_nosound = true
                end
            else
                if ent.Bon_ability_nosound then
                    ent.Bon_ability_nosound = false

                    if ent.CaughtEnemy_gentoi_bon then
                        ent.CaughtEnemy_gentoi_bon = nil
                    end
                end
            end


            local puppet = ent:GetPuppet()
            if ent.jumpscarenetity then
                if IsValid( ent.jumpscarenetity ) then 
                    if ent.clickingminigame-CurTime() > 0 then 
                        ent.jumpscarenetity:SetPos(puppet:GetPos() + puppet:GetForward() * 70)
                    end
                end
            end

            if not ent.storedanim then
                local puppet = ent:GetPuppet()

                if IsValid(puppet) then
                    local sequence = puppet:LookupSequence("holding")

                    if sequence >= 0 then
                        local layeredAnim = puppet:AddLayeredSequence(sequence, 1)

                        ent.storedanim = layeredAnim
                        ent.storedanimprog = 0

                        puppet:SetLayerWeight(layeredAnim, 0)
                        puppet:SetLayerPriority(layeredAnim, 10)
                        puppet:SetLayerCycle(layeredAnim, 0)
                        puppet:SetLayerPlaybackRate(layeredAnim, 1)
                    end
                end
            end



            if not ent.Ragdollentity then
                ent.Ragdollentity = NULL
            end

            local puppet = ent:GetPuppet()

            puppet:SetLayerWeight(ent.storedanim, ent.storedanimprog)
            local shouldnt = true

            if ent.FakePuppet_witheredbon_gentoi and IsValid(ent.FakePuppet_witheredbon_gentoi) then shouldnt = false end
            if ply:GetNWInt("DisableMovement_jumpscare_pill_bon_withered") >= CurTime() then shouldnt = false end
            if SherlockHNS and (ply.SherlockLocked or ply.SherlockKillLocked) then shouldnt = false end

            if ent:GetNW2Bool("HoldingDownMenu_space_bon") and shouldnt then
                if not IsValid(ent.Ragdollentity) then
                    local attackPos = ent:LocalToWorld(Vector(0, 0, 50))

                    for _, ent2 in ipairs(ents.FindInSphere(attackPos, 120)) do
                        if ent2 == ent then continue end
                        if not IsValid(ent2) then continue end
                        if ent2:GetClass() ~= "prop_ragdoll" then continue end
                        local ragdoll = ent2
                        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                            local phys = ragdoll:GetPhysicsObjectNum(i)

                            if IsValid(phys) then
                                phys:EnableMotion(true)
                                phys:Wake()
                            end
                        end
                        ent.Ragdollentity = ent2

                        local puppet = ent:GetPuppet()

                        if IsValid(puppet) then
                            puppet:CallOnRemove("ResetHeldRagdoll", function()
                                local ragdoll = ent.Ragdollentity

                                if IsValid(ragdoll) then

                                    ragdoll:SetCollisionGroup(COLLISION_GROUP_NONE)

                                    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                                        local phys = ragdoll:GetPhysicsObjectNum(i)

                                        if IsValid(phys) then
                                            phys:EnableMotion(true)
                                            phys:Wake()
                                        end
                                    end
                                end

                                ent.Ragdollentity = NULL
                            end)
                        end

                        break
                    end
                else

                    local ragdoll = ent.Ragdollentity

                    if IsValid(puppet) and IsValid(ragdoll) then

                        local handR = puppet:LookupBone("Hand.R")
                        local handL = puppet:LookupBone("Hand.L")

                        if handR and handL then

                            local posR = puppet:GetBonePosition(handR)
                            local posL = puppet:GetBonePosition(handL)

                            if posR and posL then

                                local medianPos = (posR + posL) * 0.5

                                local puppetAng = puppet:GetAngles()
                                local targetAng = Angle(0, puppetAng.y, 0)

                                local targetPhys
                                local torsoPhys

                                for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                                    local phys = ragdoll:GetPhysicsObjectNum(i)

                                    if IsValid(phys) then
                                        local boneIndex = ragdoll:TranslatePhysBoneToBone(i)

                                        if boneIndex and boneIndex >= 0 then
                                            local boneName = ragdoll:GetBoneName(boneIndex)

                                            if boneName and boneName ~= "__INVALIDBONE__" then
                                                local lowerName = string.lower(boneName)

                                                if string.find(lowerName, "head", 1, true) then
                                                    local parentBone = ragdoll:GetBoneParent(boneIndex)
                                                    torsoPhys = parentBone

                                                    if parentBone and parentBone >= 0 then
                                                        local parentPhysBone = ragdoll:TranslateBoneToPhysBone(parentBone)

                                                        if parentPhysBone and parentPhysBone >= 0 then
                                                            local parentPhys = ragdoll:GetPhysicsObjectNum(parentPhysBone)

                                                            if IsValid(parentPhys) then
                                                                targetPhys = parentPhys
                                                                break
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end

                                targetPhys = targetPhys or torsoPhys

                                local pitchOffset = -90
                                local yawOffset = -90
                                local rollOffset = 0

                                local finalAng = targetAng + Angle(
                                    pitchOffset,
                                    yawOffset,
                                    rollOffset
                                )

                                medianPos = medianPos + finalAng:Forward()*2
--
                                if IsValid(targetPhys) then
                                    targetPhys:EnableMotion(false)
                                    targetPhys:SetPos(medianPos)
                                    targetPhys:SetAngles(finalAng)
                                else
                                    ragdoll:SetPos(medianPos)
                                    ragdoll:SetAngles(finalAng)
                                end

                                ent.storedanimprog = Lerp(FrameTime()*8, ent.storedanimprog, 1)

                                ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)

                            end
                        end
                    end
                end

            else
                if IsValid(ent.Ragdollentity) then
                    local ragdoll = ent.Ragdollentity
                    local puppet = ent:GetPuppet()

                    if IsValid(puppet) then
                        puppet:RemoveCallOnRemove("ResetHeldRagdoll")
                    end

                    ragdoll:SetCollisionGroup(COLLISION_GROUP_NONE)

                    if IsValid(ragdoll) then

                        ragdoll:SetCollisionGroup(COLLISION_GROUP_NONE)

                        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                            local phys = ragdoll:GetPhysicsObjectNum(i)

                            if IsValid(phys) then
                                phys:EnableMotion(true)
                                phys:Wake()
                            end
                        end
                    end
                end
                ent.storedanimprog = Lerp(FrameTime()*8, ent.storedanimprog, 0)
                ent.Ragdollentity = NULL
            end



        end
    end,

    onRemove = function(ent)
        if SERVER then
            --print("[BON PILL DEBUG] Pill entity is being removed, cleaning up...")
            
            -- Remove CCTV camera
            RemoveCCTVCamera(ent)
            
            -- Cleanup any jumpscares
            for _, ply in pairs(player.GetAll()) do
                if IsValid(ply) then
                    -- Remove movement restrictions
                    ply:SetNWInt("DisableMovement_jumpscare_pill_bon", 0)
                    
                    -- Cleanup client effects
                    net.Start("bon_emergency_cleanup_withered")
                    net.WriteEntity(ent:GetPuppet() or ent)
                    net.Send(ply)
                    
                    --print("[BON PILL DEBUG] Cleaned up jumpscare state for " .. ply:Nick())
                end
            end
            
            --print("[BON PILL DEBUG] Pill cleanup completed")
        end
    end
})

