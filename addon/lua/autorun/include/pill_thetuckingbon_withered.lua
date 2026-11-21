
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

local function bonjackietien_jumpscare(ply, ent, duration, customanimstuff)
    if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
    if ent.IsInJumpscare >= CurTime() then return end

    local jumpscare_entity = nil

    for _, ent2 in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 70)) do
        if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
            if ent2 == ply then continue end
            if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

            if IsValid(ent2) then
                jumpscare_entity = ent2
                break
            end
        end
    end

    if jumpscare_entity ~= nil then
        ent.jumpscare_entity = jumpscare_entity
        jumpscare_entity:SetPos(ply:GetPos() + ent:GetPuppet():GetForward() * 75)

        local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

        targetAngle.p = 0
        targetAngle.r = 0

        jumpscare_entity:SetAngles(targetAngle)

        ply:SetNWInt("DisableMovement_jumpscare_pill_bon_withered", duration+CurTime())
        jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_bon_withered", duration+CurTime())

        ent.IsInJumpscare = CurTime() + duration

        local puppet = ent:GetPuppet()

        if jumpscare_entity:IsPlayer() then
            net.Start('bon_jumpscare_gen_withered')
            net.WriteEntity(puppet)
            net.WriteBool(true)
            net.Send(jumpscare_entity)
        else
            jumpscare_entity:NextThink(duration+0.1+CurTime())
        end

        timer.Simple(duration, function()
            if !(IsValid(jumpscare_entity)) or !IsValid(ent) then return end

            if jumpscare_entity:IsPlayer() then
                jumpscare_entity:Kill(ply)

                net.Start('bon_jumpscare_gen_withered')
                net.WriteEntity(puppet)
                net.WriteBool(false)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:TakeDamage(1e9, ply)
            end

            AdvancedPillSound({
                stringe = {
                    "gentoi/witheredbon/WITHEREDBONVOICELINE1.wav",
                    "gentoi/witheredbon/WITHEREDBONVOICELINE2.wav",
                    "gentoi/witheredbon/WITHEREDBONVOICELINE3.wav",
                    "gentoi/witheredbon/WITHEREDBONVOICELINE4.wav"
                },
                pitchPercent = 100,
                soundLevel = 67
            }, ent)
        end)

        customanimstuff()
    end
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

    attack = {
        mode = 'trigger',
        func = function(ply, ent)
            if IsValid(ent.Ragdollentity) then return end


            if ent:GetNW2Float("jup_delyay_bon") >= CurTime() then return end
            if ent:GetNW2Float("trueform_duration") > CurTime() then return end
            local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("kill"))
            bonjackietien_jumpscare(
                ply,
                ent,
                dur,
                function()
                    ent:PillSound('jumpscares')
                    ent:PillAnim('jumpscare')

                    local entity = ent.jumpscare_entity
                    if entity:LookupBone("ValveBiped.Bip01_Pelvis") then
                        local JumpscareAnimEntity = ents.Create('prop_dynamic')
                        JumpscareAnimEntity:SetModel('models/Gentoi/walterfiles/bon/killanim.mdl')
                        JumpscareAnimEntity:SetPos(ent:GetPuppet():GetPos()+ent:GetPuppet():GetForward()*3+ent:GetPuppet():GetUp()*5)
                        JumpscareAnimEntity:SetAngles(ent:GetPuppet():GetAngles()+Angle(0,180,0))
                        JumpscareAnimEntity:SetParent(ent:GetPuppet())
                        JumpscareAnimEntity:Spawn()
                        ent:DeleteOnRemove(JumpscareAnimEntity)

                        JumpscareAnimEntity:ResetSequence('skeleton')

                        local JumpscareFakeEntity = ents.Create('prop_dynamic')
                        JumpscareFakeEntity:SetModel(entity:GetModel())
                        JumpscareFakeEntity:SetParent(JumpscareAnimEntity)
                        JumpscareFakeEntity:AddEffects(EF_BONEMERGE)
                        JumpscareFakeEntity:Fire('SetParentAttachment','camera')
                        JumpscareFakeEntity:Spawn()
                        ent:DeleteOnRemove(JumpscareFakeEntity)
                        ent:SetNWEntity("JumpscareDeathThing_ent", JumpscareFakeEntity)
                        JumpscareFakeEntity:SetNWEntity("JumpscareDeathThing_ent_scp096", entity)

                        local oldcolor = entity:GetColor()
                        local oldRender = entity:GetRenderMode()
                        entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
                        entity:SetColor(Color(255, 255, 255, 0))
                        entity:SetNoDraw(true)
						if entity:IsPlayer() then
							entity:SetActiveWeapon(nil)
						end

                        ent:CallOnRemove("jumpscareend_afkeacfharcter_"..ent:EntIndex(), function()
                            if IsValid(entity) then
                                if IsValid(JumpscareAnimEntity) then
                                    JumpscareAnimEntity:Remove()
                                end
                                if IsValid(JumpscareFakeEntity) then
                                    JumpscareFakeEntity:Remove()
                                end
                                entity:SetNoDraw(false)
                                entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
                                entity:SetColor(Color(255, 255, 255, 255))
                                entity:SetRenderMode(oldRender)
                                entity:SetColor(oldcolor)
                            end
                        end)

                        timer.Simple(dur,function()
                            if !IsValid(ent) then return end
                            ent:RemoveCallOnRemove("jumpscareend_afkeacfharcter_"..ent:EntIndex())

                            JumpscareAnimEntity:SetParent(NULL)
                            ent:SetNWEntity("JumpscareDeathThing_ent", NULL)

                            if IsValid(JumpscareAnimEntity) and IsValid(JumpscareFakeEntity) then

                                local rag = ents.Create("prop_ragdoll")
                                rag:SetModel(JumpscareFakeEntity:GetModel())
                                rag:SetPos(JumpscareAnimEntity:GetPos() + ent:GetPuppet():GetForward()*30 )
                                local anglething = JumpscareFakeEntity:GetAngles()
                                anglething:RotateAroundAxis(JumpscareAnimEntity:GetForward(), 90)
                                anglething:RotateAroundAxis(JumpscareAnimEntity:GetUp(), 90)
                                rag:SetAngles(anglething+Angle(0,180,0))
                                rag:Spawn()

                                JumpscareAnimEntity:Remove()
                                JumpscareFakeEntity:Remove()
                            end
                            if IsValid(entity) then
                                entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
                                entity:SetColor(Color(255, 255, 255, 255))
                            end
                        end)
                    end

                end
            )
        end
    },

    attack2 = {
        mode = 'tick',
        func = function(ply, ent)
        end
    },

    noragdoll=true,

    use_bonz=function(ply,ent)
        --[[
        if not ent.jumpscareduratino then ent.jumpscareduratino = -1 end
        if not ent.clickingminigame then ent.clickingminigame = -1 end

        if ent.clickingminigame-CurTime() < 0 then return end

        local current_Bon_bonClicking_ds = ent:GetNWInt("Bon_bonClicking_ds", 0)
        ent:SetNWInt("Bon_bonClicking_ds", current_Bon_bonClicking_ds + 1)]]

    end,

    reload=function(ply,ent)
        --[[
        if not ent.stealthCooldown then ent.stealthCooldown = 0 end

        if ent.stealthDuration >= CurTime() then
            ply:ChatPrint("You must wait ".. math.Round(ent.stealthCooldown - CurTime(), 1) .. " second before you can use stealthiness again. Ability lasts " .. math.Round(ent.stealthDuration - CurTime(), 1) .. " seconds. ")
            return
        end

        if ent.stealthCooldown >= CurTime() then
            ply:ChatPrint("You must wait ".. math.Round(ent.stealthCooldown - CurTime(), 1) .. " second before you can use stealthiness again.")
            return
        end

        ent.stealthDuration = CurTime() + 60
        ent.stealthCooldown = ent.stealthDuration + 30]]
    end,

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
            if ply:GetNWInt("DisableMovement_jumpscare_pill_bon_withered") >= CurTime() then return end
            if IsValid(ent.Ragdollentity) then return end
            if SERVER then
                if ent.FakePuppet_witheredbon_gentoi and IsValid(ent.FakePuppet_witheredbon_gentoi) then
                    ply:SetPos(ent.FakePuppet_witheredbon_gentoi:GetPos())
                    ent.FakePuppet_witheredbon_gentoi:Remove()
                    ent:GetPuppet():SetNW2Float("witheredbon_2ddisplay_gentoi", 0)
                    ent:SetNWBool("FakePuppet_witheredbon_gentoi", false)
                    ent:SetNW2Float("trueform_duration", 0)

                    local CD = GetConVar("GentoiPills_bon_canuse_trueform_cd_failed"):GetFloat()
                    ent:SetNW2Float("Bon_abilitycd", CurTime()+ CD)
                    ent:SetNW2Float("Bon_abilitycd_dur", CD)
                else
                    if GetConVar("GentoiPills_bon_canuse_trueform"):GetBool() then else return end
                    if ent:GetNW2Float("Bon_abilitycd") >= CurTime() then return end
                    local puppet = ents.Create("prop_dynamic")
                    puppet:SetModel("models/gentoi/walterfiles/witheredbon.mdl")
                    puppet:Spawn()

                    puppet:SetPos(ent:GetPuppet():GetPos())
                    puppet:SetAngles(ent:GetPuppet():GetAngles())

                    ent:DeleteOnRemove(puppet)

                    local seq = puppet:LookupSequence("idle")
                    puppet:ResetSequence(seq)
                    puppet:SetCycle(0)
                    puppet:SetPlaybackRate(1)

                    ent.FakePuppet_witheredbon_gentoi = puppet
                    ent:SetNWBool("FakePuppet_witheredbon_gentoi", true)

                    local CD = GetConVar("GentoiPills_bon_canuse_trueform_duration"):GetFloat()

                    ent:SetNW2Float("trueform_duration", CurTime()+CD)
                    ent:SetNW2Float("Bon_abilitycd", CurTime()+ CD)
                    ent:SetNW2Float("Bon_abilitycd_dur", CD)
                end
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
            if not ent.VoiceLineDelay then ent.VoiceLineDelay = 0 end

            if ent.VoiceLineDelay >= CurTime() then
                return
            end

            local soundgo = {
                [0] = "dark/bon/BONsound1.mp3",
                [1] = "dark/bon/BONsound2.mp3",
                [2] = "gentoi/witheredbon/BonLaughNew.wav"
            }

            local key = math.random(0,2)

            if soundgo[key] ~= nil then
                local duration = SoundDuration(soundgo[key])

                ent.VoiceLineDelay = CurTime() + duration

                AdvancedPillSound(
                    {
                        stringe = soundgo[key],
                    },
                    ent
                )
            end
        end
    end,
        
    jump = function(ply, ent) end,

    bon_gentoi_stats = {
        moveSpeed = {
            walk = 64,
            run = 420,
            ducked= 64,
            jumppower= 0,
        },
    },

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
            
            ent:SetNW2Bool("GentoiPills_bon_canuse_trueform",GetConVar("GentoiPills_bon_canuse_trueform"):GetBool())

            local speed = {
                ['walk'] = GetConVar("GentoiPills_bon_walkspeed"):GetFloat(),
                ['run'] = GetConVar("GentoiPills_bon_runspeed"):GetFloat(),
                ['ducked'] = GetConVar("GentoiPills_bon_crouchspeed"):GetFloat(),
                ['jumppower'] =GetConVar("GentoiPills_bon_jumppower"):GetFloat(),
            }
            local puppet = ent:GetPuppet()
            puppet:SetRenderMode(RENDERMODE_TRANSALPHA)
            if ent.FakePuppet_witheredbon_gentoi and IsValid(ent.FakePuppet_witheredbon_gentoi) then

                speed["walk"] = speed["walk"] + GetConVar("GentoiPills_bon_trueform_walkadd"):GetFloat()
                speed["run"] = speed["run"] + GetConVar("GentoiPills_bon_trueform_runadd"):GetFloat()
                speed["ducked"] = speed["ducked"] + GetConVar("GentoiPills_bon_trueform_crouchadd"):GetFloat()

                if ent:GetNW2Float("trueform_duration") < CurTime() then
                    ent.FakePuppet_witheredbon_gentoi:Remove()
                    timer.Simple(0,function()
                        if !IsValid(ent) then return end
                        ply:SetPos(ent.FakePuppet_witheredbon_gentoi:GetPos())
                        ent:GetPuppet():SetNW2Float("witheredbon_2ddisplay_gentoi", 0)
                        ent:SetNWBool("FakePuppet_witheredbon_gentoi", false)
                        ent:SetNW2Float("trueform_duration", 0)

                        local CD = GetConVar("GentoiPills_bon_canuse_trueform_cd_failed"):GetFloat()
                        ent:SetNW2Float("Bon_abilitycd", CurTime()+ CD)
                        ent:SetNW2Float("Bon_abilitycd_dur", CD)
                    end)
                end

                ent:GetPuppet():SetNW2Float("witheredbon_2ddisplay_gentoi", CurTime()+0.1)
                puppet:SetColor(Color(255,255,255,0))

                if ply:GetPos():Distance(ent.FakePuppet_witheredbon_gentoi:GetPos()) > 1100 then

                    local attackPos = ent.FakePuppet_witheredbon_gentoi:GetPos()

                    for _, ent2 in pairs(ents.FindInSphere(attackPos, GetConVar("GentoiPills_bon_canuse_trueform_oldbody_detectionrange"):GetFloat())) do
                        if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.01 then
                            if ent2 == ply then continue end
                            if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end
                            if bit.band(ent2:GetFlags(), FL_NOTARGET) ~= 0 then continue end

                            if ent2:IsPlayer() or ent2:IsNPC() or ent2:IsNextBot() then

                                ent2:SetNW2Float("outline_witheredbon_gentoi_distance", CurTime() + 0.1)

                            end
                        end
                    end
                end

                local attackPos = ent:LocalToWorld(Vector(0, 0, 50))

                for _, ent2 in pairs(ents.FindInSphere(attackPos, 120)) do
                    if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.01 then
                        if ent2 == ply then continue end
                        if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end
                        if bit.band(ent2:GetFlags(), FL_NOTARGET) ~= 0 then continue end

                        if ent2:IsPlayer() or ent2:IsNPC() or ent2:IsNextBot() then

                            ent2:SetNW2Float("outline_witheredbon_gentoi", CurTime() + GetConVar("GentoiPills_bon_canuse_trueform_outlineduration"):GetFloat())
                            ent2:SetNW2Float("jup_delyay_bon", CurTime() + 0.75)

                            ent.FakePuppet_witheredbon_gentoi:Remove()
                            timer.Simple(0,function()
                                if !IsValid(ent) then return end
                                ply:SetPos(ent.FakePuppet_witheredbon_gentoi:GetPos())
                                ent:GetPuppet():SetNW2Float("witheredbon_2ddisplay_gentoi", 0)
                                ent:SetNWBool("FakePuppet_witheredbon_gentoi", false)
                                ent:SetNW2Float("trueform_duration", 0)

                                local CD = GetConVar("GentoiPills_bon_canuse_trueform_cd_hit"):GetFloat()
                                ent:SetNW2Float("Bon_abilitycd", CurTime()+ CD)
                                ent:SetNW2Float("Bon_abilitycd_dur", CD)

                                ent:SetNW2Float("Bon_ability_nosound", CurTime()+ GetConVar("GentoiPills_bon_canuse_trueform_nosoundduration"):GetFloat())
                            end)
                            if ent2:IsPlayer() then
                                ent.CaughtEnemy_gentoi_bon = ent2

                                net.Start('OM_gentoi_witheredbon_PlayGlobalSound')
                                net.Send(ent2)
                                net.Start("gentoi_bon_2djumpscare")
                                net.Send(ent2)
                            end

                        end
                    end
                end

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

            --ent:SetNW2Float("WalkAnimrate_witheredbon", speed["walk"]/64)
            --ent:SetNW2Float("RunAnimrate_witheredbon", speed["run"]/420)
            --ent:SetNW2Float("CrouchAnimrate_witheredbon", speed["ducked"]/64)

            if IsValid(ply) and IsValid(ent) then
                ply:SetWalkSpeed(speed["walk"])
                ply:SetRunSpeed(speed["run"])
                ply:SetCrouchedWalkSpeed(speed["ducked"])
                ply:SetJumpPower(speed["jumppower"])
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

