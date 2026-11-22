if !pcall(require,"pk_pills") then
    if SERVER then
        hook.Add("PlayerInitialSpawn","pk_pill_extfail_cl",function(ply)
            if game.SinglePlayer() || ply:IsListenServerHost() then
                ply:SendLua('notification.AddLegacy("One or more pill extensions failed to load. Did you forget to install Parakeet\'s Pill Pack?",NOTIFY_ERROR,30)')
            end
        end)
        hook.Add("Initialize","pk_pill_extfail_sv",function(ply)
            print("[ALERT] One or more pill extensions failed to load. Did you forget to install Enhanced Parakeet's Pill Base?")
        end)
    end
    return
end

AddCSLuaFile()
include("include/pill_thetuckingbon_withered.lua")


if SERVER then
    util.AddNetworkString("gentoi_bon_2djumpscare")
end
if CLIENT then



    local preservedmats = {
        ["bon_char1"] = Material("gentoi/witheredbon/bon_char1.png"),
        ["bon_char2"] = Material("gentoi/witheredbon/bon_char2.png"),
        ["black_circle"] = Material("gentoi/witheredbon/black_circle.png", "smooth"),
        ["RATICONGMOD"] = Material("gentoi/rat/RATICONGMOD.png"),

        ["WITHEREDBONBG"] = Material("gentoi/witheredbon/WITHEREDBONBG.png"),
        ["WITHEREDBONICONUI"] = Material("gentoi/witheredbon/WITHEREDBONICONUI.png"),
        ["WITHEREDBONTEXTUI"] = Material("gentoi/witheredbon/WITHEREDBONTEXTUI.png"),
        ["WITHEREDBONABILITYTEXTUI"] = Material("gentoi/witheredbon/WITHEREDBONABILITYTEXTUI.png"),
        ["WITHEREDBONABILITYICONUI"] = Material("gentoi/witheredbon/WITHEREDBONABILITYICONUI.png"),

        ["TRUEFORMICON1"] = Material("gentoi/witheredbon/TRUEFORMICON1.png"),
        ["TRUEFORMICON2"] = Material("gentoi/witheredbon/TRUEFORMICON2.png"),
    }

    local old = "Normal"

    surface.CreateFont("CreditsText_Large_bon", {
        font = "Arial",
        size = 70,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("OM_SlashKey", {
        font = "Roboto",
        size = 32,
        weight = 700,
        antialias = true
    })

    local startime = CurTime()
    local jumpscareenabled = false



    local jee = Material("gentoi/witheredBon/jee.vtf")
    net.Receive("gentoi_bon_2djumpscare", function()
        local curFrame = 0
        local start = CurTime()

        jumpscareenabled = true

        surface.PlaySound("gentoi/witheredbon/bonjumpdca2.wav")
        
        hook.Add( "DrawOverlay", "drawjee", function()
            local ct = CurTime()
            
            curFrame = math.ceil((ct - start) * 12)
            
            render.SetMaterial(jee)
            
                jee:SetInt("$frame", curFrame) 
                
            render.DrawScreenQuad()
        end)
        
        timer.Simple(1.7, function()
            LocalPlayer():ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 255), 2, 0)
            hook.Remove("DrawOverlay", "drawjee")
        end)
    end)

    hook.Add("HUDPaint", "gent_bon_hudpaint_fnac", function()
        local ply = LocalPlayer()
        if !IsValid(ply) then return end

        local pillentity = ply.pk_pill_ent
        if not IsValid(pillentity) then return end
        if not pillentity.GetPuppet then return end
        if not IsValid(pillentity:GetPuppet()) then return end
        if not pillentity.formTable._bon_pill_ds_withered then return end

		local curtime = CurTime()

        local screenW, screenH = ScrW(), ScrH()



        pillentity.HoldingDownMenu_bon_lerp = pillentity.HoldingDownMenu_bon_lerp or 0
        pillentity.HoldingDownMenu_bon_lerp_bg = pillentity.HoldingDownMenu_bon_lerp_bg or 0
        pillentity.HoldingDownMenu_bon_lerp_char = pillentity.HoldingDownMenu_bon_lerp_char or 0
        pillentity.HoldingDownMenu_bon_lerp_text = pillentity.HoldingDownMenu_bon_lerp_text or 0
        pillentity.HoldingDownMenu_bon_lerp_bio = pillentity.HoldingDownMenu_bon_lerp_bio or 0
        pillentity.HoldingDownMenu_bon_lerp_ability = pillentity.HoldingDownMenu_bon_lerp_ability or 0

        if pillentity:GetNWBool("HoldingDownMenu_bon") then
            pillentity.HoldingDownMenu_bon_lerp = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_bon_lerp, 1)
            if curtime-pillentity:GetNW2Float('HoldingDownMenu_bon_timeframe') > 0.45 then
                pillentity.HoldingDownMenu_bon_lerp_bg = Lerp( FrameTime() * 13, pillentity.HoldingDownMenu_bon_lerp_bg, 1)
                pillentity.HoldingDownMenu_bon_lerp_ability = Lerp( FrameTime() * 13, pillentity.HoldingDownMenu_bon_lerp_ability, 1)

                pillentity.HoldingDownMenu_bon_lerp_char = Lerp( FrameTime() * 7, pillentity.HoldingDownMenu_bon_lerp_char, 1)
                pillentity.HoldingDownMenu_bon_lerp_text = Lerp( FrameTime() * 7, pillentity.HoldingDownMenu_bon_lerp_text, 1)
                pillentity.HoldingDownMenu_bon_lerp_bio = Lerp( FrameTime() * 7, pillentity.HoldingDownMenu_bon_lerp_bio, 1)

                if not pillentity.PlayRatSound_1 then
                    pillentity.PlayRatSound_1 = true
                    sound.PlayFile("sound/gentoi/witheredbon/HELPHUDOPEN.wav", "noplay", function(station, err)
                        if IsValid(station) then
                            station:SetVolume(0.3)
                            station:Play()
                        end
                    end)
                end
            end
        else
            pillentity.HoldingDownMenu_bon_lerp_bg = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_bon_lerp_bg, 0)
            pillentity.HoldingDownMenu_bon_lerp_char = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_bon_lerp_char, 0)
            pillentity.HoldingDownMenu_bon_lerp_text = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_bon_lerp_text, 0)
            pillentity.HoldingDownMenu_bon_lerp_bio = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_bon_lerp_bio, 0)
            pillentity.HoldingDownMenu_bon_lerp_ability = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_bon_lerp_ability, 0)
            if pillentity.PlayRatSound_1 then
                pillentity.PlayRatSound_1 = false
                sound.PlayFile("sound/gentoi/witheredbon/HELPHUDEXIT.wav", "noplay", function(station, err)
                    if IsValid(station) then
                        station:SetVolume(0.3)
                        station:Play()
                    end
                end)
            end
            if curtime-pillentity:GetNW2Float('HoldingDownMenu_bon_timeframe') > 0.45 then
                pillentity.HoldingDownMenu_bon_lerp = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_bon_lerp, 0)
            end
        end


        local w = ScreenScale(20)
        local h = ScreenScale(40)
        local inset = ScreenScale(10)

        local offset = Lerp(pillentity.HoldingDownMenu_bon_lerp, 0, ScreenScale(25))

        local x = 0
        local y = ScreenScale(25)

        draw.NoTexture()

        surface.SetDrawColor(25, 25, 25, 220)
        surface.DrawPoly({
            {x = x- offset,     y = y},
            {x = x + w- offset, y = y + inset},
            {x = x + w- offset, y = y + h - inset},
            {x = x- offset,     y = y + h},
        })


        surface.SetDrawColor(255, 0, 0)

        surface.DrawLine(x - offset,     y,             x + w - offset, y + inset)
        surface.DrawLine(x + w - offset, y + inset,     x + w - offset, y + h - inset)
        surface.DrawLine(x + w - offset, y + h - inset, x - offset,     y + h)

        draw.SimpleText(
            "/",
            "OM_SlashKey",
            x + w * 0.55- offset,
            y + h * 0.5,
            color_white,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )


        local currentaadd = Lerp(pillentity.HoldingDownMenu_bon_lerp, 0, screenW*0.1)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_bon_lerp_bg))
        surface.SetMaterial(preservedmats["WITHEREDBONBG"])
        surface.DrawTexturedRect(-screenW*0.1+currentaadd,0,screenW,screenH)


        local currentaadd = Lerp(pillentity.HoldingDownMenu_bon_lerp_char, 0, screenW*0.1)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_bon_lerp_char))
        surface.SetMaterial(preservedmats["WITHEREDBONICONUI"])
        surface.DrawTexturedRect(-screenW*0.1+currentaadd,0,screenW,screenH)


        local currentaadd = Lerp(pillentity.HoldingDownMenu_bon_lerp_text, 0, screenH*0.1)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_bon_lerp_text))
        surface.SetMaterial(preservedmats["WITHEREDBONTEXTUI"])
        surface.DrawTexturedRect(0,screenH*0.1-currentaadd,screenW,screenH)


        local currentaadd = Lerp(pillentity.HoldingDownMenu_bon_lerp_bio, 0, screenW*0.1)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_bon_lerp_bio))
        surface.SetMaterial(preservedmats["WITHEREDBONABILITYTEXTUI"])
        surface.DrawTexturedRect(screenW*0.1-currentaadd,0,screenW,screenH)


        local currentaadd = Lerp(pillentity.HoldingDownMenu_bon_lerp_ability, 0, screenW*0.025)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_bon_lerp_ability))
        surface.SetMaterial(preservedmats["WITHEREDBONABILITYICONUI"])
        surface.DrawTexturedRect(-screenW*0.025+currentaadd,0,screenW,screenH)
        
    end)


end



hook.Add("PlayerButtonUp", "deactivateKeybind_noodles_bon", function(ply, button)
    local pillentity = ply.pk_pill_ent

    if IsValid(pillentity) then
        if pillentity.formTable.deactivateKeybind_noodles_bon then
            pillentity.formTable.deactivateKeybind_noodles_bon(ply, pillentity, button)
        end
    end
end)
hook.Add("PlayerButtonDown", "ActivateKeybind_noodles_bon", function(ply, button)
    local pillentity = ply.pk_pill_ent
    if IsValid(pillentity) then
        if pillentity.formTable.ActivateKeybind_noodles_bon then
            pillentity.formTable.ActivateKeybind_noodles_bon(ply, pillentity, button)
        end
    end
end)





if SERVER then

    local function CreateAConvVarConstant(VarName, DefaultSetting, Text,min,max)
        CreateConVar(VarName, DefaultSetting, FCVAR_ARCHIVE, Text, min, max)     
    end
    CreateAConvVarConstant("GentoiPills_bon_hasintroanim",1,"", 0,1) 


    --Bon_abilitycd
    CreateAConvVarConstant("GentoiPills_bon_canuse_trueform",1,"", 0,1) 
    CreateAConvVarConstant("GentoiPills_bon_canuse_trueform_cd_hit",25,"", 0,1e9) 
    CreateAConvVarConstant("GentoiPills_bon_canuse_trueform_cd_failed",15,"", 0,1e9) 
    CreateAConvVarConstant("GentoiPills_bon_canuse_trueform_duration",20,"", 0,1e9) 
    CreateAConvVarConstant("GentoiPills_bon_canuse_trueform_nosoundduration",20,"", 0,1e9) 
    CreateAConvVarConstant("GentoiPills_bon_canuse_trueform_outlineduration",20,"", 0,1e9) 


    CreateAConvVarConstant("GentoiPills_bon_canuse_trueform_oldbody_detectionrange",500,"", 0,1e9) 
else

    hook.Add("PopulateToolMenu", "Gentoi_pill_WitheredBon_populate", function()   

        spawnmenu.AddToolMenuOption("Gentoi Pill Settings", "Pills", "Gentoi_pills_WitheredBon", "Withered Bon", "", "", function(panel)

            panel:Help("------------ Withered Bon ------------")


            panel:Help("-- Preset --")
            local presettable = {
                name = "Gentoi_pills_Bon_presets",

                listofdefualtconvars = {
                    "GentoiPills_bon_hasintroanim",


                    "GentoiPills_bon_canuse_trueform",
                    "GentoiPills_bon_canuse_trueform_cd_hit",
                    "GentoiPills_bon_canuse_trueform_cd_failed",
                    "GentoiPills_bon_canuse_trueform_duration",
                    "GentoiPills_bon_canuse_trueform_nosoundduration",
                    "GentoiPills_bon_canuse_trueform_outlineduration",


                    "GentoiPills_bon_canuse_trueform_oldbody_detectionrange"
                }
            }

            local presetName = presettable.name
            local listofdefualtconvars = presettable.listofdefualtconvars

            local combo = vgui.Create("DComboBox")
            combo:Dock(TOP)
            combo:SetTall(30)
            combo:SetValue("Default")

            local saveButton = vgui.Create("DButton")
            saveButton:Dock(TOP)
            saveButton:SetTall(25)
            saveButton:SetText("Save Current")

            local editButton = vgui.Create("DButton")
            editButton:Dock(TOP)
            editButton:SetTall(25)
            editButton:SetText("Edit Presets")

            panel:AddItem(combo)
            panel:AddItem(saveButton)
            panel:AddItem(editButton)

            local PRESET_FOLDER = "OM_LNZ"
            local PRESET_FILE = PRESET_FOLDER .. "/preset_" .. presetName .. ".json"

            local function EnsureFolder()
                if not file.Exists(PRESET_FOLDER, "DATA") then
                    file.CreateDir(PRESET_FOLDER)
                end
            end

            local function LoadPresets()
                EnsureFolder()

                if not file.Exists(PRESET_FILE, "DATA") then
                    return {}
                end

                return util.JSONToTable(file.Read(PRESET_FILE, "DATA")) or {}
            end

            local function SavePresets(presets)
                EnsureFolder()
                file.Write(PRESET_FILE, util.TableToJSON(presets, true))
            end

            local defaultValues = {}

            for _, cvar in ipairs(listofdefualtconvars) do
                local cv = GetConVar(cvar)

                if cv then
                    defaultValues[cvar] = cv:GetDefault()
                end
            end

            local function RefreshDropdown()
                combo:Clear()
                combo:AddChoice("Default")

                for name in pairs(LoadPresets()) do
                    combo:AddChoice(name)
                end
            end

            RefreshDropdown()

            function combo:OnSelect(_, value)
                if value == "Default" then
                    for cvar, default in pairs(defaultValues) do
                        RunConsoleCommand(cvar, tostring(default))
                    end

                    return
                end

                local preset = LoadPresets()[value]
                if not preset then return end

                for cvar, value in pairs(preset) do
                    RunConsoleCommand(cvar, tostring(value))
                end
            end

            saveButton.DoClick = function()
                Derma_StringRequest(
                    "Save Preset",
                    "Preset name:",
                    "",
                    function(name)
                        if not name or name == "" then return end

                        local presets = LoadPresets()
                        presets[name] = {}

                        for _, cvar in ipairs(listofdefualtconvars) do
                            local cv = GetConVar(cvar)

                            if cv then
                                presets[name][cvar] = cv:GetString()
                            end
                        end

                        SavePresets(presets)
                        RefreshDropdown()
                        combo:SetValue(name)
                    end
                )
            end

            local function OpenPresetEditor()
                local presets = LoadPresets()

                local frame = vgui.Create("DFrame")
                frame:SetSize(550, 420)
                frame:Center()
                frame:SetTitle("Preset Editor - " .. presetName)
                frame:MakePopup()

                local list = vgui.Create("DListView", frame)
                list:Dock(LEFT)
                list:SetWide(160)
                list:AddColumn("Presets")

                for name in pairs(presets) do
                    list:AddLine(name)
                end

                local right = vgui.Create("DScrollPanel", frame)
                right:Dock(FILL)

                local selected

                list.OnRowSelected = function(_, _, row)
                    right:Clear()
                    selected = row:GetColumnText(1)

                    for cvar, value in pairs(presets[selected] or {}) do
                        local rowPanel = right:Add("DPanel")
                        rowPanel:Dock(TOP)
                        rowPanel:SetTall(30)
                        rowPanel:DockMargin(4, 4, 4, 4)

                        local label = rowPanel:Add("DLabel")
                        label:Dock(LEFT)
                        label:SetWide(250)
                        label:SetText(cvar)

                        local entry = rowPanel:Add("DTextEntry")
                        entry:Dock(FILL)
                        entry:SetValue(value)

                        entry.OnChange = function(self)
                            presets[selected][cvar] = self:GetValue()
                        end
                    end
                end

                local bottom = vgui.Create("DPanel", frame)
                bottom:Dock(BOTTOM)
                bottom:SetTall(35)

                local save = bottom:Add("DButton")
                save:Dock(LEFT)
                save:SetWide(100)
                save:SetText("Save")
                save.DoClick = function()
                    SavePresets(presets)
                    RefreshDropdown()
                end

                local delete = bottom:Add("DButton")
                delete:Dock(RIGHT)
                delete:SetWide(100)
                delete:SetText("Delete")
                delete.DoClick = function()
                    if not selected then return end

                    presets[selected] = nil
                    SavePresets(presets)

                    frame:Close()
                    RefreshDropdown()
                end

                local rename = bottom:Add("DButton")
                rename:Dock(FILL)
                rename:SetText("Rename")
                rename.DoClick = function()
                    if not selected then return end

                    Derma_StringRequest(
                        "Rename Preset",
                        "New name:",
                        selected,
                        function(name)
                            if not name or name == "" or presets[name] then return end

                            presets[name] = presets[selected]
                            presets[selected] = nil

                            SavePresets(presets)
                            frame:Close()
                            RefreshDropdown()
                        end
                    )
                end
            end

            editButton.DoClick = OpenPresetEditor
            panel:Help("-- Misc --")
            panel:CheckBox("Intro Anim","GentoiPills_bon_hasintroanim")
            panel:Help("")


            panel:Help("-- True Form --")
            panel:CheckBox("Can Be Used","GentoiPills_bon_canuse_trueform")
            panel:NumSlider("CD Hit","GentoiPills_bon_canuse_trueform_cd_hit",0,30)
            panel:NumSlider("CD Failed","GentoiPills_bon_canuse_trueform_cd_failed",0,30)
            panel:NumSlider("Ability Duration","GentoiPills_bon_canuse_trueform_duration",0,30)
            panel:NumSlider("No Sound Hit Duration","GentoiPills_bon_canuse_trueform_nosoundduration",0,30)
            panel:NumSlider("Outline Hit Duration","GentoiPills_bon_canuse_trueform_outlineduration",0,30)
            panel:NumSlider("Old Body Outline Range","GentoiPills_bon_canuse_trueform_oldbody_detectionrange",0,100)
            panel:Help("")
        end)        
    end)
end