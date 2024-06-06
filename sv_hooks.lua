local PLUGIN = PLUGIN

-- FUNC CheckLegsBroken: Проверяет сломаны ли ноги.
function CheckLegsBroken(ply)
    local char = ply:GetCharacter()

    if not char then return end

    local healthStatus = char:GetHealthStatus()
    local bodyParts = healthStatus.bodyParts
    local leftLegBreak = bodyParts[HITGROUP_LEFTLEG] and bodyParts[HITGROUP_LEFTLEG].broken or false
    local rightLegBreak = bodyParts[HITGROUP_RIGHTLEG] and bodyParts[HITGROUP_RIGHTLEG].broken or false

    local legSlowEffect = ix.config.Get('legSlowEffect') / 100
    local walkSpeedBase = ix.config.Get('walkSpeed')
    local runSpeedBase = ix.config.Get('runSpeed')

    if leftLegBreak or rightLegBreak then
        local multi = (leftLegBreak and 1 or 0) + (rightLegBreak and 1 or 0)
        local slowingEffect = legSlowEffect / (multi + 1)
        ply:SetWalkSpeed(walkSpeedBase * slowingEffect)
        ply:SetRunSpeed(runSpeedBase * slowingEffect)
    else
        ply:SetWalkSpeed(walkSpeedBase)
        ply:SetRunSpeed(runSpeedBase)
    end
end

-- FUNC UpdateHealthVars: Обновляет значения состояния здоровья, такие как сердечный ритм, давления и т.п.
function UpdateHealthVars(ply)
    local char = ply:GetCharacter()

    if not char then return end

    local healthStatus = char:GetHealthStatus()

    local cardiacOutput = GetCardiacOutput(healthStatus.blood, healthStatus.heartRate)
    local lowBP, highBP = CalculateBloodPressure(cardiacOutput, healthStatus.resistance)
    local newHeartRate = CalculateHeartRate(healthStatus.blood, healthStatus.heartAttack, lowBP, highBP, healthStatus.heartRate, healthStatus.spo2, healthStatus.pain)
    healthStatus.cardiacOutput = cardiacOutput
    healthStatus.highBP = highBP
    healthStatus.heartRate = newHeartRate

    char:SetHealthStatus(healthStatus)
end

-- FUNC HealthTracker: Запускает трекер для обновления значения состояния здоровья.
function HealthTracker()
    local updateDelay = ix.config.Get('healthInfoUpdateDelay')

    local timerID = 'HealthTracker'

    if not timer.Exists(timerID) then
        timer.Create(timerID, updateDelay, 0, function ()
            local players = player.GetAll()

            for _, ply in ipairs(players) do
                local char = ply:GetCharacter()
                if char then
                    UpdateHealthVars(ply)
                end
            end
        end)
    end
end

-- FUNC Trackers: Хук, который запускает трекер.
hook.Add('InitPostEntity', 'Trackers', function()
    HealthTracker()
end)

-- FUNC GetEquippedWeapon: Возвращает экипированное оружие, находящееся в руках.
local function GetEquippedWeapon(player) -- +
    local char = player:GetCharacter()
    local activeWeapon = player:GetActiveWeapon()

    if not activeWeapon then return nil end

    local weapons = char:GetInventory():GetItemsByBase('base_weapons')

    for _, weapon in ipairs(weapons) do
        if weapon:GetData('equip') and (weapon.class == activeWeapon:GetClass()) then
            return weapon
        end
    end

    return nil
end

-- FUNC DropInventoryItem: Выбрасывает предмет, удаляя его из инвентаря и спавня в мире, отбрасывая его от игрока.
local function DropInventoryItem(player, itemId) -- +
    local throwVelocity = 100
    local char = player:GetCharacter()

    if not char then return end

    local inventory = char:GetInventory()
    local item = inventory:GetItemByID(itemId)

    if not item then return end

    local forward = player:EyeAngles():Forward()
    local dropPosition = player:GetPos() + forward * 50 + Vector(0, 0, 10)

    ix.item.Spawn(item.uniqueID, dropPosition, function(spawnedItem, entity)
        local physObj = entity:GetPhysicsObject()

        if IsValid(physObj) then
            physObj:SetVelocity(forward * throwVelocity)
        end
    end)

    inventory:Remove(itemId)
end

-- FUNC UnequipAllWeapons: Убирает все экипированные предметы из рук.
local function UnequipAllWeapons(player)
    local character = player:GetCharacter()

    if not character then return end

    local weapons = character:GetInventory():GetItemsByBase('base_weapons')

    for i, weapon in ipairs(weapons) do
        weapon:Unequip(player, true)
    end
end

-- FUNC BecomeRagdoll: Превращает игрока в рэгдолл.
local function BecomeRagdoll(player) -- +
    if not IsValid(player) or not player:Alive() then return end

    local character = player:GetCharacter()

    if not character then return end

    local healthStatus = character:GetHealthStatus()

    if not healthStatus or not healthStatus.unconscious then return end

    if not character:GetData('ragdollEntity', nil) then
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll:SetPos(player:GetPos())
        ragdoll:SetModel(player:GetModel())
        ragdoll:SetAngles(player:GetAngles())
        ragdoll:SetSkin(player:GetSkin())
        ragdoll:SetColor(player:GetColor())
        ragdoll:SetMaterial(player:GetMaterial())
        ragdoll:SetNWEntity("Owner", player)
        
        --ragdoll:SetHitboxSet(player:GetHitboxSet())

        for i = 0, player:GetNumBodyGroups() - 1 do
            ragdoll:SetBodygroup(i, player:GetBodygroup(i))
        end

        ragdoll:Spawn()
        ragdoll:Activate()
        ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

        character:SetData('ragdollEntity', ragdoll)
    end

    local currentWeapon = GetEquippedWeapon(player)
    if currentWeapon then
        DropInventoryItem(player, currentWeapon:GetID())
    end

    player:Spectate(OBS_MODE_IN_EYE)
    player:SpectateEntity(ragdoll)

    UnequipAllWeapons(player)

    player:StripWeapons()
end

-- FUNC ExitRagdoll: Превращает рэгдолл-игрока в игрока.
local function ExitRagdoll(player) -- +
    local character = player:GetCharacter()

    if not character then return end

    local healthStatus = character:GetHealthStatus()

    if not healthStatus or healthStatus.unconscious then return end

    local ragdoll = character:GetData('ragdollEntity', nil)

    if not IsValid(player) then return end

    player:UnSpectate()
    player:Spawn()

    if ragdoll then
        player:SetPos(ragdoll:GetPos())
        player:SetEyeAngles(ragdoll:GetAngles())
        ragdoll:Remove()
    end

    character:SetData('ragdollEntity', nil)
end

-- FUNC ManageHealthState: В зависимости от условий отслеживает потерю сознания и сердечный приступ.
function ManageHealthState(ply)
    local unconsciousOn = ix.config.Get('unconsciousOn')
    if not unconsciousOn then return end

    local char = ply:GetCharacter()
    if not char then return end

    local charId = char:GetID()
    local timerID = 'manageHealthState' .. charId
    local heartAttackTimerId = 'subheartAttackTimer' .. charId

    local healthStateCheckInterval = ix.config.Get('healthStateCheckInterval')
    local bloodLossUnconscious = ix.config.Get('bloodLossUnconscious')
    local painThresholdUnconscious = ix.config.Get('painThresholdUnconscious')
    local chanceWakeUp = ix.config.Get('chanceWakeUp')
    local chanceLoseConsciousness = ix.config.Get('chanceLoseConsciousness')
    local heartAttackBlood = ix.config.Get('heartAttackBlood')
    local heartAttackChance = ix.config.Get('heartAttackChance')
    local durationheartAttack = ix.config.Get('durationheartAttack')
    local minFatalHeartRate = ix.config.Get('minFatalHeartRate')
    local maxFatalHeartRate = ix.config.Get('maxFatalHeartRate')

    local function UpdateHealthStatus()
        return char:GetHealthStatus()
    end

    local healthStatus = UpdateHealthStatus()

    if not timer.Exists(timerID) then
        timer.Create(timerID, healthStateCheckInterval, 0, function()
            healthStatus = UpdateHealthStatus()
            local curPain = healthStatus.pain
            local blood = healthStatus.blood
            local heartRate = healthStatus.heartRate

            if healthStatus.unconscious then
                local awakeRand = math.random(0, 100)
                if blood > bloodLossUnconscious and curPain < painThresholdUnconscious and awakeRand < chanceWakeUp then
                    healthStatus.unconscious = false
                    char:SetHealthStatus(healthStatus)
                    ExitRagdoll(ply)
                end
            else
                local unconsciousRand = math.random(0, 100)
                if (blood < bloodLossUnconscious or curPain > painThresholdUnconscious) or (heartRate < minFatalHeartRate) or (heartRate > maxFatalHeartRate) and unconsciousRand < chanceLoseConsciousness then
                    healthStatus.unconscious = true
                    char:SetHealthStatus(healthStatus)
                    BecomeRagdoll(ply)
                end
            end

            if (blood < heartAttackBlood) or (heartRate < minFatalHeartRate) or (heartRate > maxFatalHeartRate) then
                if not healthStatus.heartAttack then
                    local heartAttackRand = math.random(0, 100)
                    if heartAttackRand < heartAttackChance then
                        healthStatus.heartAttack = true
                        if not timer.Exists(heartAttackTimerId) then
                            timer.Create(heartAttackTimerId, durationheartAttack, 1, function()
                                local healthStatus = UpdateHealthStatus()
                                if healthStatus.heartAttack then
                                    ply:Kill()
                                end
                            end)
                        end
                        healthStatus.timers[heartAttackTimerId] = heartAttackTimerId
                        char:SetHealthStatus(healthStatus)
                    end
                end
            else
                healthStatus.heartAttack = false
                if timer.Exists(heartAttackTimerId) then
                    timer.Remove(heartAttackTimerId)
                    healthStatus.timers[heartAttackTimerId] = nil
                end
                char:SetHealthStatus(healthStatus)
            end

            if not healthStatus.unconscious and not healthStatus.heartAttack then
                timer.Remove(timerID)
                healthStatus.timers[timerID] = nil
                char:SetHealthStatus(healthStatus)
            end
        end)

        healthStatus.timers[timerID] = timerID
        char:SetHealthStatus(healthStatus)
    end
end

-- FUNC StartBleedingTracker: В зависимости от условий отслеживает потерю крови, фатальные раны, боль и моментальную потерю сознания от повреждений.
local function StartBleedingTracker(ply)
    if not IsValid(ply) then return end

    local character = ply:GetCharacter()
    if not character then return end

    local charId = character:GetID()
    local bleedTrackerTimerId = 'bleedingTracker' .. charId

    if not timer.Exists(bleedTrackerTimerId) then
        local headFatalDamage = ix.config.Get('headFatalDamage')
        local organFatalDamage = ix.config.Get('organFatalDamage')
        local bleedTrackerTick = ix.config.Get('bleedTrackerTick')
        local damageThreshold = ix.config.Get('damageThreshold')
        local penetrationThreshold = ix.config.Get('PENETRATION_THRESHOLD')
        local painThresholdUnconscious = ix.config.Get('painThresholdUnconscious')
        local bloodMax = ix.config.Get('blood')
        local weibullFatalDamageL = ix.config.Get('weibullFatalDamageL')
        local weibullFatalDamageK = ix.config.Get('weibullFatalDamageK')
        local painMax = ix.config.Get('pain')
        local heartHitChance = ix.config.Get('heartHitChance')

        local function UpdateHealthStatus()
            return character:GetHealthStatus()
        end

        local healthStatus = UpdateHealthStatus()

        timer.Create(bleedTrackerTimerId, bleedTrackerTick, 0, function()
            healthStatus = UpdateHealthStatus()
            if healthStatus.bleedStatus then
                local sumBleeding = 0
                local sumPain = 0
                local curBlood = healthStatus.blood
                local sumDamage = { [HITGROUP_HEAD] = 0, [HITGROUP_CHEST] = 0, [HITGROUP_STOMACH] = 0}
                local numWounds = 0

                for _, bodyPart in ipairs(healthStatus.bodyParts) do
                    for _, wound in ipairs(bodyPart.wounds) do
                        sumBleeding = sumBleeding + wound.bleeding
                        sumPain = sumPain + wound.pain
                        if wound.damage >= penetrationThreshold then
                            if not sumDamage[bodyPart.hitgroup] then
                                sumDamage[bodyPart.hitgroup] = 0
                            end

                            sumDamage[bodyPart.hitgroup] = sumDamage[bodyPart.hitgroup] + wound.damage
                        end
                        numWounds = numWounds + 1
                    end
                end

                local headDamage = sumDamage[HITGROUP_HEAD]
                local organDamage = sumDamage[HITGROUP_CHEST] + sumDamage[HITGROUP_STOMACH]
                local heartHitRand = math.random(0, 100)

                if headDamage >= headFatalDamage then
                    ply:Kill()
                    return
                elseif organDamage >= organFatalDamage and heartHitRand <= heartHitChance then
                    ply:Kill()
                    return
                end

                local bodyDamage = 0

                for i, damageBodyPart in pairs(sumDamage) do
                    bodyDamage = bodyDamage + damageBodyPart
                end

                local headThreshhold = 1.25 * damageThreshold
                local bodyThreshhold = 1.5 * damageThreshold
                local vitalDamage = math.max(headDamage - headThreshhold, 0) + math.max(bodyDamage - bodyThreshhold, 0)
                local chanceFatal = 1 - math.exp(-(vitalDamage / weibullFatalDamageL) ^ weibullFatalDamageK)

                if (chanceFatal * 100) > math.random(0, 100) then
                    ply:Kill()
                    return
                end

                if (headDamage > damageThreshold / 2) or (bodyDamage > damageThreshold) or (sumPain >= painThresholdUnconscious) then
                    if not healthStatus.unconscious then
                        healthStatus.unconscious = true
                        character:SetHealthStatus(healthStatus)
                        BecomeRagdoll(ply)
                    end
                end

                if sumPain >= painMax then
                    if not healthStatus.unconscious then
                        healthStatus.unconscious = true
                        character:SetHealthStatus(healthStatus)
                        BecomeRagdoll(ply)
                    end
                end

                healthStatus.bleed = sumBleeding
                healthStatus.blood = math.Clamp(curBlood - sumBleeding, 0, bloodMax)
                healthStatus.pain = math.Clamp(sumPain, 0, 1)

                if sumBleeding > 0 then
                    util.Decal("Blood", ply:GetPos(), ply:GetPos() + Vector(0, 0, -50), ply)
                end

                if numWounds <= 0 then
                    healthStatus.bleedStatus = false
                end
            else
                healthStatus.bleedStatus = false
                healthStatus.timers[bleedTrackerTimerId] = nil
                timer.Remove(bleedTrackerTimerId)
            end

            character:SetHealthStatus(healthStatus)
            ManageHealthState(ply)
        end)

        healthStatus.timers[bleedTrackerTimerId] = bleedTrackerTimerId
        character:SetHealthStatus(healthStatus)
    end
end

-- FUNC ConvertLinear: Производит линейную интерполяцию.
local function ConvertLinear(inputMin, inputMax, inputValue, outputMin, outputMax, clamp) -- +
    local inputRange = inputMax - inputMin
    local outputRange = outputMax - outputMin
    local normalizedValue = (inputValue - inputMin) / inputRange
    local outputValue = outputMin + normalizedValue * outputRange

    if clamp then
        outputValue = math.max(outputMin, math.min(outputValue, outputMax))
    end

    return outputValue
end

-- FUNC HandleFallDamage: Обрабатывает события падения. Определяет на какую ногу пришлось повреждение.
local function HandleFallDamage(player, isFallDamage, hitgroup, healthStatus) -- +
    if isFallDamage then
        local leftLeg = healthStatus.bodyParts[HITGROUP_LEFTLEG]
        local rightLeg = healthStatus.bodyParts[HITGROUP_RIGHTLEG]

        if leftLeg and leftLeg.broken and (not rightLeg or not rightLeg.broken) then
            return HITGROUP_RIGHTLEG
        else
            return HITGROUP_LEFTLEG
        end
    end
    return hitgroup
end

-- FUNC HandleWeaponStrip: Обрабатывает попадание в руку, шанс выбить оружие.
local function HandleWeaponStrip(player, bodyPart) -- +
    if bodyPart.hitgroup == HITGROUP_LEFTARM or bodyPart.hitgroup == HITGROUP_RIGHTARM then
        local stripChance = ix.config.Get('stripWeaponChance')

        if math.random(1, 100) <= stripChance then
            local currentWeapon = GetEquippedWeapon(player)
            if currentWeapon then
                DropInventoryItem(player, currentWeapon:GetID())
            end
        end
    end
end

-- FUNC HandleBreakage: Обрабатывает ломание костей.
local function HandleBreakage(player, bodyPart, isFallDamage) -- +
    if not bodyPart.broken then
        local fallDistance = player:GetNWFloat("LastFallHeight")
        local fractureChance = ix.config.Get('fracturesChance')
        local fallBreakThreshold = ix.config.Get('fallBreak')
        local fallDeathThreshold = ix.config.Get('fallDeath')

        if isFallDamage and fallDistance >= fallBreakThreshold then
            fractureChance = math.Clamp(((fallDistance - fallBreakThreshold) / (fallDeathThreshold - fallBreakThreshold)) * 100, 0, 100)
        end

        local breakRandom = math.random(0, 100)

        if breakRandom <= fractureChance then
            bodyPart.broken = true

            if bodyPart.hitgroup == HITGROUP_CHEST then
                local breathSoundPath = 'breathSound.wav'

                local character = player:GetCharacter()
                local characterID = character:GetID()
                local timerID = "SoundEffect_" .. characterID .. breathSoundPath
                local soundDuration = SoundDuration(breathSoundPath)

                local function UpdateHealthStatus()
                    return character:GetHealthStatus()
                end

                local healthStatus = UpdateHealthStatus()

                timer.Create(timerID, soundDuration, 0, function()
                    healthStatus = UpdateHealthStatus()
                    local chestStatus = healthStatus.bodyParts[HITGROUP_CHEST].broken

                    if not chestStatus then
                        healthStatus.timers[timerID] = nil
                        character:SetHealthStatus(healthStatus)
                        timer.Remove(timerID)
                    else
                        local currentBlood = healthStatus.blood
                        local maxBlood = ix.config.Get('blood')
                        local normalizedBlood = currentBlood / maxBlood
                        local pitch = math.Clamp(100 * normalizedBlood, 0, 255)
                        local volume = math.Clamp(1 * normalizedBlood, 0, 1)

                        player:EmitSound(breathSoundPath, 100, pitch, volume)
                    end
                end)

                healthStatus.timers[timerID] = timerID
                character:SetHealthStatus(healthStatus)
            end

            player:EmitSound('boneBroke.mp3', 100, 100, 1)
        end
    end
end

-- FUNC DetermineNumWounds: Определяет количество ран от попадания.
local function DetermineNumWounds(damage, thresholds) -- +
    local numThresholds = #thresholds

    if damage >= thresholds[1][1] then
        return thresholds[1][2]
    elseif damage < thresholds[numThresholds][1] then
        return thresholds[numThresholds][2]
    end

    for i = 2, numThresholds do
        local threshold = thresholds[i]
        local prevThreshold = thresholds[i - 1]

        if damage >= threshold[1] and damage < prevThreshold[1] then
            local interpolation = ConvertLinear(threshold[1], prevThreshold[1], damage, threshold[2], prevThreshold[2], true)
            return math.floor(interpolation + 0.5)
        end
    end

    return 1
end

-- FUNC DetermineChancesWounds: Определяет шансы для разных типов ран.
local function DetermineChancesWounds(damagePerWound, damageTypeData) -- +
    local function InterpolateWeight(weighting)
        local numWeights = #weighting

        if damagePerWound >= weighting[1][1] then
            return weighting[1][2]
        elseif damagePerWound <= weighting[numWeights][1] then
            return weighting[numWeights][2]
        end

        for i = 2, numWeights do
            local lowerBound = weighting[i][1]
            local upperBound = weighting[i - 1][1]
            local lowerWeight = weighting[i][2]
            local upperWeight = weighting[i - 1][2]

            if damagePerWound >= lowerBound and damagePerWound < upperBound then
                return ConvertLinear(lowerBound, upperBound, damagePerWound, lowerWeight, upperWeight, true)
            end
        end

        return 0
    end

    local weights = {}
    local totalWeight = 0

    for damageType, data in pairs(damageTypeData.damages) do
        local weight = InterpolateWeight(data.weighting)
        weights[damageType] = weight
        totalWeight = totalWeight + weight
    end

    local probabilities = {}
    for damageType, weight in pairs(weights) do
        probabilities[damageType] = weight / totalWeight
    end

    return probabilities
end

-- FUNC DetermineWoundSize: Определяет размер ран.
local function DetermineWoundSize(woundDamage, sizeMultiplier, largeWoundThreshold) -- +
    sizeMultiplier = sizeMultiplier or 1

    return ConvertLinear(0.1, ix.config.Get('worstDamage'), woundDamage * sizeMultiplier, largeWoundThreshold, 1, true)
end

-- FUNC ChooseRandomKey: В зависимости от шансов типов ран определяет тип раны.
local function ChooseRandomKey(probabilities) -- +
    local totalProbability = 0
    for _, probability in pairs(probabilities) do
        totalProbability = totalProbability + probability
    end

    local randomNumber = math.random() * totalProbability

    for key, probability in pairs(probabilities) do
        if randomNumber <= probability then
            return key
        end
        randomNumber = randomNumber - probability
    end
end

-- FUNC: Вычисляет потерю крови в секунду. (лит./cек.)
function CalculateBloodLossPerSecond(cardiacOutput, bleeding) -- +
    local bloodLossPerMinute = cardiacOutput * bleeding;
    return bloodLossPerMinute;
end

-- FUNC CalculateBloodPressure: Вычисляет кровяное давление.
function CalculateBloodPressure(cardiacOutput, resistance)
    local MODIFIER_BP_HIGH = 9.4736842
    local MODIFIER_BP_LOW = 6.3157894

    local bloodPressure = cardiacOutput * resistance

    local lowBP = math.Round(bloodPressure * MODIFIER_BP_LOW)
    local highBP = math.Round(bloodPressure * MODIFIER_BP_HIGH)

    return lowBP, highBP
end

local lastSpo = 100

-- FUNC CalculateHeartRate: Вычисляет сердечный ритп. (удар./мин.)
function CalculateHeartRate(curBlood, heartAttackStatus, heartRate, BPH, BPL, spo2, painLevel)
    local hrTargetAdjustment = 0
    local deltaT = 1

    local hrChange = 0
    local targetHR = 0

    if heartAttackStatus then
        hrChange = 0
    else
        local bloodVolume = curBlood
        local bloodVolumeClass = 0

        if bloodVolume > ix.config.Get('criticalBloodLoss') then
            bloodVolumeClass = 4
        elseif bloodVolume > ix.config.Get('severeBloodLoss') then
            bloodVolumeClass = 3
        elseif bloodVolume > ix.config.Get('moderateBloodLoss') then
            bloodVolumeClass = 2
        elseif bloodVolume > 0 then
            bloodVolumeClass = 1
        end

        if bloodVolumeClass > 0 then
            local meanBP = (2 / 3) * BPH + (1 / 3) * BPL
            local targetBP = 107

            if bloodVolumeClass < 3 then
                targetBP = targetBP * (bloodVolume / ix.config.Get('blood'))
            end

            targetHR = heartRate
            if bloodVolumeClass < 2 then
                targetHR = heartRate * (targetBP / math.max(45, meanBP))
            end

            if painLevel > 0.2 then
                targetHR = math.max(targetHR, 80 + 50 * painLevel)
            end

            local staminaForce = (lastSpo - spo2) * 0.4
            lastSpo = spo2

            targetHR = targetHR + staminaForce
            targetHR = targetHR + hrTargetAdjustment
            targetHR = math.max(targetHR, 0)

            hrChange = math.Round(targetHR - heartRate) / 2
        else
            hrChange = -math.Round(heartRate / 10)
        end
    end

    if hrChange < 0 then
        heartRate = math.max(heartRate + deltaT * hrChange, targetHR)
    else
        heartRate = math.min(heartRate + deltaT * hrChange, targetHR)
    end

    return heartRate
end

-- FUNC GetDamageTypes: Возвращает текстовое представления типа урона, вычисляет типы урона, полученные от попадания.
local function GetDamageTypes(dmgType) -- +
    local damageTypes = {
        [0] = "DMG_GENERIC",
        [1] = "DMG_CRUSH",
        [2] = "DMG_BULLET",
        [4] = "DMG_SLASH",
        [8] = "DMG_BURN",
        [16] = "DMG_VEHICLE",
        [32] = "DMG_FALL",
        [64] = "DMG_BLAST",
        [128] = "DMG_CLUB",
        [256] = "DMG_SHOCK",
        [512] = "DMG_SONIC",
        [1024] = "DMG_ENERGYBEAM",
        [2048] = "DMG_NEVERGIB",
        [4096] = "DMG_ALWAYSGIB",
        [8192] = "DMG_DROWN",
        [16384] = "DMG_PARALYZE",
        [32768] = "DMG_NERVEGAS",
        [65536] = "DMG_POISON",
        [131072] = "DMG_RADIATION",
        [262144] = "DMG_DROWNRECOVER",
        [524288] = "DMG_ACID",
        [1048576] = "DMG_SLOWBURN",
        [2097152] = "DMG_REMOVENORAGDOLL",
        [4194304] = "DMG_PHYSGUN",
        [8388608] = "DMG_PLASMA",
        [16777216] = "DMG_AIRBOAT",
        [33554432] = "DMG_DISSOLVE",
        [67108864] = "DMG_BLAST_SURFACE",
        [134217728] = "DMG_DIRECT",
        [268435456] = "DMG_BUCKSHOT",
        [536870912] = "DMG_SNIPER",
        [1073741824] = "DMG_MISSILEDEFENSE",
    }

    local types = {}
    for bitValue, name in pairs(damageTypes) do
        if bit.band(dmgType, bitValue) == bitValue then
            table.insert(types, name)
        end
    end
    return types
end

-- FUNC DetermineWoundSizeCategory: Определяет категорию урона по размеру раны.
function DetermineWoundSizeCategory(woundSize, damagePerWound) -- +
    if woundSize >= damagePerWound then
        return 'large'
    elseif woundSize < damagePerWound and woundSize >= damagePerWound * 0.5 then
        return 'medium'
    elseif woundSize < damagePerWound * 0.5 and woundSize >= damagePerWound * 0.25 then
        return 'minor'
    else
        return 'minor'
    end
end

-- FUNC RestoreHealth: Восстанавливает состояние здоровья до обычного.
local function RestoreHealth(client) -- +
    local char = client:GetCharacter()

    if not char then return end

    local blood = ix.config.Get('blood')
    local walkSpeedBase = ix.config.Get('walkSpeed')
    local runSpeedBase = ix.config.Get('runSpeed')

    client:SetMaxHealth(blood)
    client:SetHealth(blood)
    client:SetWalkSpeed(walkSpeedBase)
    client:SetRunSpeed(runSpeedBase)

    local healthStatus = char:GetHealthStatus()

    healthStatus.unconscious = false
    char:SetHealthStatus(healthStatus)
    ExitRagdoll(client)

    for i, v in ipairs(healthStatus.timers) do
        timer.Remove(v)
    end

    char:SetData('health', blood)
    char:SetHealthStatus(PLUGIN:initHealth())
end

-- FUNC SpawnDeathRagdoll: Спавнит рэгдолл игрока после его смерти. Удаляется после истечения таймера.
local function SpawnDeathRagdoll(player)
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetPos(player:GetPos())
    ragdoll:SetModel(player:GetModel())
    ragdoll:SetAngles(player:GetAngles())
    ragdoll:SetSkin(player:GetSkin())
    ragdoll:SetColor(player:GetColor())
    ragdoll:SetMaterial(player:GetMaterial())

    for i = 0, player:GetNumBodyGroups() - 1 do
        ragdoll:SetBodygroup(i, player:GetBodygroup(i))
    end

    ragdoll:Spawn()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

    timer.Simple(ix.config.Get('deathRagdollRemoveDelay'), function()
        ragdoll:Remove();
    end)
end

hook.Add('DoPlayerDeath', 'TrackPlayerDeath', function (ply, attacker, dmg)
    RestoreHealth(ply)
    SpawnDeathRagdoll(ply)
end)

function PLUGIN:PreCharacterDeleted(client) -- +
    RestoreHealth(client)
end

-- FUNC AdjustStaminaOffset: Обновляет spo2 значение и при сломанной груди увеличивает потребление стамины.
function PLUGIN:AdjustStaminaOffset(client, offset) -- +
    if client:Alive() then
        local char = client:GetCharacter()

        if not char then return end

        local healthStatus = char:GetHealthStatus()

        if not healthStatus then return end

        local chestBroken = healthStatus.bodyParts[HITGROUP_CHEST].broken

        if chestBroken then
            offset = (offset * ix.config.Get('chestBrokenModifier'))
        end

        local curStamina = math.Clamp(healthStatus.spo2 + offset, 0, 100)
        healthStatus.spo2 = curStamina
        char:SetHealthStatus(healthStatus)
    end

    return offset
end

-- FUNC CanPlayerEquipItem: При потере сознания нельзя экипировать предметы.
function PLUGIN:CanPlayerEquipItem(client, item) -- +
    local char = client:GetCharacter()
    local healthStatus = char:GetHealthStatus()

    if not char then return end

    if healthStatus.unconscious then return false end
end

-- FUNC OnCharacterCreated: FIX: Здоровья пероснажа по умолчанию равно 100, хотя должно 6.0. Это костыль.
function PLUGIN:OnCharacterCreated(client, char) -- +
    local blood = ix.config.Get('blood')

    client:SetMaxHealth(blood)
    client:SetHealth(blood)

    char:SetData('health', blood)
end

-- FUNC PlayerLoadedCharacter: Восстанавливает состояние персонажа при перезаходе или загрузке персонажа.
function PLUGIN:PlayerLoadedCharacter(client, char, currentChar)
    CheckLegsBroken(client)
    StartBleedingTracker(client)
    BecomeRagdoll(client)
    ManageHealthState(client)
    local health = char:GetData('health')
    if health then
        client:SetMaxHealth(health)
    end
end

-- FUNC TrackFallStart: Определяет последнюю точку перед падением.
hook.Add("Move", "TrackFallStart", function(player, mv) -- +
    if player:IsOnGround() then
        player:SetNWFloat("FallStartHeight", player:GetPos().z)
    end
end)

-- FUNC TrackFallHeight: Определяет высоту, с которой упал игрок и является ли падением смертельным.
hook.Add("OnPlayerHitGround", "TrackFallHeight", function(player, inWater, onFloater, speed) -- +
    if inWater or onFloater then return end

    local startHeight = player:GetNWFloat("FallStartHeight", 0)
    local endHeight = player:GetPos().z
    local fallDistance = startHeight - endHeight

    player:SetNWFloat("LastFallHeight", fallDistance)

    local fatalFallHeight = ix.config.Get('fatalFallHeight')
    if fallDistance > fatalFallHeight then
        player:Kill()
        return
    end

    local damageFallHeight = ix.config.Get('damageFallHeight')
    if fallDistance > damageFallHeight then
        local damageAmount = math.max(0, (fallDistance - damageFallHeight) * 0.2)

        local dmginfo = DamageInfo()
        dmginfo:SetDamage(damageAmount)
        dmginfo:SetDamageType(DMG_FALL)
        dmginfo:SetAttacker(player)
        dmginfo:SetInflictor(player)

        player:TakeDamageInfo(dmginfo)
    end
end)

-- FUNC GetCardiacOutput: Возвращает сердечный выброс
function GetCardiacOutput(blood, heartRate)
    local maxBloodVolume = ix.config.Get('blood')
    local bloodVolumeRatio = blood / maxBloodVolume
    local entering = ConvertLinear(0.5, 1, bloodVolumeRatio, 0, 1, true)
    local VENTRICLE_STROKE_VOL = 0.095
    local cardiacOutput = (entering * VENTRICLE_STROKE_VOL) * heartRate / 60

    return cardiacOutput
end

-- FUNC EntityDamageHandler: Определяет количество, тип, размер ран, количество боли и обновляет значения в состоянии здоровья.
hook.Add("EntityTakeDamage", "EntityDamageHandler", function(entity, dmgInfo) -- +
    local damage = dmgInfo:GetDamage() * ix.config.Get('damageMultiply') * (math.random(9, 11) * 0.1)

    dmgInfo:SetDamage(0)

    local owner = entity:GetNWEntity('Owner', false) or nil

    print(entity.LastHitGroup)

    if not entity.LastHitGroup then return end

    -- FIXME исправить хитбоксы рэгдолла, чтобы правильно считывался урон и приминялся на игрока от рэгдолла.
    local lastHitGroup = entity:LastHitGroup()

    local ply = owner or entity

    if not lastHitGroup then return end

    if not ply:IsPlayer() then return end

    local character = ply:GetCharacter()
    local healthStatus = character:GetHealthStatus()

    if not healthStatus then return end

    local isFallDamage = dmgInfo:IsFallDamage()
    local hitGroup = HandleFallDamage(ply, isFallDamage, lastHitGroup, healthStatus)

    print(lastHitGroup)

    local bodyPart = healthStatus.bodyParts[hitGroup]

    if not bodyPart then return end

    local damageTypes = dmgInfo:GetDamageType()
    local activeDamageTypes = GetDamageTypes(damageTypes)

    HandleWeaponStrip(ply, bodyPart)

    for _, dtype in ipairs(activeDamageTypes) do
        local damageTypeInfo = PLUGIN.aceConfig.damageTypes[dtype]

        if damageTypeInfo then
            local numWounds = DetermineNumWounds(damage, damageTypeInfo.thresholds)
            local damagePerWound = damage / numWounds
            local woundChances = DetermineChancesWounds(damagePerWound, damageTypeInfo)
            local woundType = ChooseRandomKey(woundChances)
            local damageTypeWoundInfo = damageTypeInfo.damages[woundType]
            local woundTypeInfo = PLUGIN.aceConfig.woundTypes[woundType]

            if woundTypeInfo.causeFracture then
                HandleBreakage(ply, bodyPart, isFallDamage)
                CheckLegsBroken(ply)
            end

            local woundSize = DetermineWoundSize(damagePerWound, damageTypeWoundInfo.sizeMultiplier, 0.25)
            local woundSizeCategory = DetermineWoundSizeCategory(woundSize, damagePerWound)
            local bleedingAmount = woundSize * ix.config.Get('bleedMultiplier') * woundTypeInfo.bleeding
            local painAmount = woundSize * ix.config.Get('painMultiplier') * woundTypeInfo.pain
            local cardiacOutput = healthStatus.cardiacOutput
            local resultBleeding = CalculateBloodLossPerSecond(cardiacOutput, bleedingAmount)

            local newWounds = {}

            if woundSizeCategory then
                for i = 1, numWounds do
                    table.insert(newWounds, { type = woundType, size = woundSizeCategory, bleeding = resultBleeding, pain = painAmount, damage = damagePerWound })
                end
            end

            if #newWounds > 0 then
                healthStatus.bleedStatus = true
            end

            table.Add(bodyPart.wounds, newWounds)

            character:SetHealthStatus(healthStatus)
            StartBleedingTracker(ply)
        end
    end
end)
