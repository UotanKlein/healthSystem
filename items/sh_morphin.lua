local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Морфин"
ITEM.description = ""
ITEM.category = "Health System"
ITEM.price = 0
ITEM.model = Model("models/props_junk/PopCan01a.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.medTag = 'morphine'

-- FIXME: Исправить морфин
ITEM.functions.Use = {
	OnRun = function(itemTable)
        if SERVER then
            local client = itemTable.player
            local char = client:GetCharacter()
            local charId = char:GetID()
            local healthStatus = char:GetHealthStatus();
            local medInfo = PLUGIN.aceConfig.medication[ITEM.medTag]
    
            if not medInfo then return end
    
            local painReduce = medInfo.painReduce
            local hrIncreaseLow = medInfo.hrIncreaseLow
            local hrIncreaseNormal = medInfo.hrIncreaseNormal
            local hrIncreaseHigh = medInfo.hrIncreaseHigh
            local timeInSystem = medInfo.timeInSystem
            local timeTillMaxEffect = medInfo.timeTillMaxEffect
            local maxDose = medInfo.maxDose
            local incompatibleMedication = medInfo.incompatibleMedication
            local viscosityChange = medInfo.viscosityChange
    
            local curHR = healthStatus.heartRate
    
            local hightHeartRate = ix.config.Get('hightHeartRate')
            local lowHeartRate = ix.config.Get('lowHeartRate')
    
            local hrIncrease
    
            if curHR < lowHeartRate then
                hrIncrease = hrIncreaseLow
            elseif curHR >= lowHeartRate and curHR < hightHeartRate then
                hrIncrease = hrIncreaseNormal
            elseif curHR > hightHeartRate then
                hrIncrease = hrIncreaseHigh
            end
    
            local minIncrease = hrIncrease[1]
            local maxIncrease = hrIncrease[2]
    
            local heartRateChange = minIncrease + math.random(0, (maxIncrease - minIncrease));
    
            local morphineId = healthStatus.morphinCount + 1
            healthStatus.morphinCount = morphineId
    
            local decreasingTime = timeInSystem - timeTillMaxEffect
    
            local passedSeconds = 0
    
            local timerId = charId .. morphineId .. 'morphineTracker'
    
            local reducedPain = 0

            timer.Create(timerId, 1, timeInSystem, function ()
                passedSeconds = passedSeconds + 1
    
                healthStatus = char:GetHealthStatus();
    
                local painChange = painReduce / timeTillMaxEffect
    
                if passedSeconds <= timeTillMaxEffect then
                    healthStatus.heartRate = math.max(0, healthStatus.heartRate - (heartRateChange / timeTillMaxEffect))

                    local newPain = healthStatus.pain - painChange

                    if healthStatus.pain >= 0 and newPain < 0 then
                        newPain = newPain * -1
                    end

                    newPain = math.max(0, newPain)
    
                    reducedPain = reducedPain + newPain
                    
                    print('curPain: ' .. healthStatus.pain)
                    print('reducedPain: ' .. reducedPain)
    
                    healthStatus.pain = math.Clamp(healthStatus.pain - painChange, 0, 1)
                else
                    healthStatus.heartRate = math.max(0, healthStatus.heartRate - (reducedPain / decreasingTime))
                    healthStatus.pain = math.Clamp(healthStatus.pain + painChange, 0, 1)
                end
    
                if passedSeconds == timeInSystem then
                    healthStatus.morphinCount = healthStatus.morphinCount - 1
                    healthStatus.timers[morphineId] = nil
                end
    
                char:SetHealthStatus(healthStatus)
            end)
    
            healthStatus.timers[timerId] = timerId
    
            char:SetHealthStatus(healthStatus)
        end
	end
}
