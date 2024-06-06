hook.Add("CreateMove", "AimShake", function(cmd)
    local ply = LocalPlayer()
    local char = ply:GetCharacter()

    if not char then return end

    local healthStatus = char:GetHealthStatus()

    if not healthStatus then return end

    local amountBlood = healthStatus.blood
    local bloodHandShake = ix.config.Get('moderateBloodLoss')
    local intensity = ix.config.Get('handShakeIntensity')
    local speed = ix.config.Get('handShakeSpeed')

    local shakeFactor = (bloodHandShake - amountBlood) / bloodHandShake
    local shakeAmount = math.Clamp(shakeFactor * intensity, 0, math.huge)

    local leftArmBroken = healthStatus.bodyParts[HITGROUP_LEFTARM].broken
    local rightArmBroken = healthStatus.bodyParts[HITGROUP_RIGHTARM].broken

    local armShakeFactor = 0
    if leftArmBroken then
        armShakeFactor = armShakeFactor + ix.config.Get('leftArmShakeFactor', 1)
    end
    if rightArmBroken then
        armShakeFactor = armShakeFactor + ix.config.Get('rightArmShakeFactor', 1)
    end

    shakeAmount = shakeAmount + armShakeFactor

    local shakeOffsetX = math.sin((CurTime() * speed) * math.random(0.8, 1.2)) * shakeAmount
    local shakeOffsetY = math.cos((CurTime() * speed) * math.random(0.8, 1.2)) * shakeAmount * 0.5
    local shakeOffsetZ = math.sin((CurTime() * speed) * math.random(0.8, 1.2)) * shakeAmount * 0.5

    local compensationX = -shakeOffsetZ * 0.5
    local compensationY = -shakeOffsetZ * 0.5

    local viewAngles = cmd:GetViewAngles() + Angle(shakeOffsetX + compensationX, shakeOffsetY + compensationY, 0)
    cmd:SetViewAngles(viewAngles)
end)

--Исправить проблему пролага
hook.Add("RenderScreenspaceEffects", "LowHealthEffect", function()
    local ply = LocalPlayer()
    local char = ply:GetCharacter()

    if char then
        local healthStatus = char:GetHealthStatus()

        if not healthStatus then return end
    
        local amountBlood = healthStatus.blood
        local maxBlood = ix.config.Get('blood')
        local grayBlood = ix.config.Get('moderateBloodLoss')
        
        local bloodDifference = math.max(maxBlood - amountBlood, 0.1)

        local tab = {}
        tab["$pp_colour_addr"] = 0
        tab["$pp_colour_addg"] = 0
        tab["$pp_colour_addb"] = 0
        tab["$pp_colour_brightness"] = 0
        tab["$pp_colour_contrast"] = 1
        tab["$pp_colour_mulr"] = 0
        tab["$pp_colour_mulg"] = 0
        tab["$pp_colour_mulb"] = 0
    
        tab["$pp_colour_colour"] = 1 - (bloodDifference / maxBlood)

        print('pp_colour_colour: ' .. (bloodDifference / maxBlood))
    
        if amountBlood < grayBlood then
            local toyTownScale = math.min(20000 / bloodDifference, 50)
            local motionBlurScale = math.min(1000 / bloodDifference, 1)
            local motionBlurAlpha = math.min(3000 / bloodDifference, 1)
            local motionBlurAngle = math.min(60 / bloodDifference, 10)

            print('toyTownScale: ' .. toyTownScale)
            print('motionBlurScale: ' .. motionBlurScale)
            print('motionBlurAlpha: ' .. motionBlurAlpha)
            print('motionBlurAngle: ' .. motionBlurAngle)
            
            --DrawToyTown(toyTownScale, (ScrH() * ((amountBlood - maxBlood) * -1 ) / maxBlood))
            --DrawMotionBlur(motionBlurScale, motionBlurAlpha, motionBlurAngle)
        else
            --DrawToyTown(0, 0)
            --DrawMotionBlur(0, 0, 0)
        end
    
        --DrawColorModify(tab)
    end
end)

local function PlaySoundEffect(ply, soundPath, configBlood, effects)
    local char = ply:GetCharacter()
    if not char then return end

    local charID = char:GetID()
    local healthStatus = char:GetHealthStatus()
    if not healthStatus then return end

    local amountBlood = healthStatus.blood

    local soundEffect = ply.soundEffects and ply.soundEffects[soundPath] or CreateSound(ply, soundPath)

    if not soundEffect then return end

    if amountBlood < configBlood then
        soundEffect:Play()
        effects(soundEffect)

        if not ply.soundEffects then
            ply.soundEffects = {}
        end

        ply.soundEffects[soundPath] = soundEffect

        local soundDur = SoundDuration(soundPath)
        local timerID = "SoundEffect_" .. charID .. soundPath

        if not timer.Exists(timerID) then
            timer.Create(timerID, soundDur, 0, function()
                if IsValid(soundEffect) then
                    soundEffect:Play()
                end
            end)
        end
    else
        if ply.soundEffects and ply.soundEffects[soundPath] then
            ply.soundEffects[soundPath]:Stop()
            ply.soundEffects[soundPath] = nil
            timer.Remove("SoundEffect_" .. charID .. soundPath)
        end
    end
end

local lastUpdateTime = 0

hook.Add("Think", "PlayCharacterSounds", function()
    if (CurTime() - lastUpdateTime) >= ix.config.Get('healthInfoUpdateDelay') then
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local char = ply:GetCharacter()
        if not char then return end

        local healthStatus = char:GetHealthStatus()
        if not healthStatus then return end

        local amountBlood = healthStatus.blood
        local heartRate = healthStatus.heartRate
        local heartAttackBlood = ix.config.Get('heartAttackBlood')

        PlaySoundEffect(ply, 'heartbeat.wav', ix.config.Get('severeBloodLoss', 6000), function(soundEffect)
            soundEffect:ChangeVolume(heartAttackBlood / amountBlood, 0)
            soundEffect:ChangePitch(math.Clamp((10 / 3) * heartRate - 100, 0, 255))
        end)

        local headBroken = healthStatus.bodyParts[HITGROUP_HEAD].broken
        if headBroken then
            PlaySoundEffect(ply, 'tinnitus.wav', ix.config.Get('blood', 6000), function(soundEffect)
                soundEffect:ChangeVolume(1, 0)
                soundEffect:ChangePitch(100, 0)
            end)
            ply:SetDSP(14, false)
        end

        lastUpdateTime = CurTime()
    end
end)

hook.Add("CalcView", "CameraShake", function(ply, pos, angles, fov)
    local char = ply:GetCharacter()

    if not char then return end

    local healthStatus = char:GetHealthStatus()

    if not healthStatus then return end

    if healthStatus.unconscious then
        local ragdoll = ply:GetObserverTarget()
        if not IsValid(ragdoll) then return end
        
        -- Получаем индекс части тела "голова"
        local headIndex = ragdoll:LookupAttachment("eyes")
        if headIndex == 0 then
            headIndex = ragdoll:LookupAttachment("head")
        end

        if headIndex == 0 then return end

        -- Получаем позицию и углы головы рэгдола
        local headPos, headAng = ragdoll:GetAttachment(headIndex)

        local view = {}
        view.origin = headPos
        view.angles = headAng
        view.fov = fov

        return view
    else
        local amountBlood = healthStatus.blood
        local bloodScreenShake = ix.config.Get('moderateBloodLoss', 6000)
    
        local intensity = ix.config.Get('screenShakeIntensity', 1)
        local speed = ix.config.Get('screenShakeSpeed', 1)
        local shakeFactor = (bloodScreenShake - amountBlood) / bloodScreenShake
    
        local shakeAmount = math.Clamp(shakeFactor * intensity, 0, math.huge)
    
        local leftArmBroken = healthStatus.bodyParts[HITGROUP_LEFTARM].broken
        local rightArmBroken = healthStatus.bodyParts[HITGROUP_RIGHTARM].broken
    
        local armShakeFactor = 0
        if leftArmBroken then
            armShakeFactor = armShakeFactor + ix.config.Get('leftArmShakeFactor', 1)
        end
        if rightArmBroken then
            armShakeFactor = armShakeFactor + ix.config.Get('rightArmShakeFactor', 1)
        end
    
        shakeAmount = shakeAmount + armShakeFactor
    
        local shakeOffset = Vector(
            math.sin(CurTime() * speed) * shakeAmount,
            math.cos(CurTime() * speed) * shakeAmount,
            math.sin(CurTime() * speed * 0.5) * shakeAmount * 0.5
        )
    
        return {origin = pos + shakeOffset, angles = angles, fov = fov}
    end
end)

local blackAlpha = 0
local blackDuration = 1
local fadeStartTime = 0

hook.Add("HUDPaint", "DrawBlackScreen", function()
    local ply = LocalPlayer()

    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    local healthStatus = char:GetHealthStatus()

    if not healthStatus then return end

    local shouldShowBlackScreen = healthStatus.unconscious

    if shouldShowBlackScreen then
        if blackAlpha < 255 then
            if fadeStartTime == 0 then
                fadeStartTime = RealTime()
            end
            local elapsedTime = RealTime() - fadeStartTime
            blackAlpha = math.Clamp((elapsedTime / blackDuration) * 255, 0, 255)
        end
    else
        if blackAlpha > 0 then
            if fadeStartTime == 0 then
                fadeStartTime = RealTime()
            end
            local elapsedTime = RealTime() - fadeStartTime
            blackAlpha = math.Clamp(255 - (elapsedTime / blackDuration) * 255, 0, 255)
        end
    end

    if not shouldShowBlackScreen and blackAlpha == 0 then
        fadeStartTime = 0
    elseif shouldShowBlackScreen and blackAlpha == 255 then
        fadeStartTime = 0
    end

    if blackAlpha > 0 then
        surface.SetDrawColor(0, 0, 0, blackAlpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end)
