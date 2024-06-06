
PLUGIN.name = "Health System"
PLUGIN.description = ""
PLUGIN.author = "`Adik"

ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_config.lua")
ix.util.Include("sh_commands.lua")
ix.util.Include("sh_aceconfig.lua")

local function initializeBodyPart(name, bleedingConfig, hitgroup)
    return {
        name = name,
        hitgroup = hitgroup,
        broken = false,
        bleeding = {
            tick = bleedingConfig,
            stage = 0,
        },
        wounds = {},
    }
end

local function getBodyParts()
    return {
        [1] = initializeBodyPart('Голова', 'headBleedTick', HITGROUP_HEAD),
        [2] = initializeBodyPart('Грудь', 'chestBleedTick', HITGROUP_CHEST),
        [3] = initializeBodyPart('Живот', 'stomachBleedTick', HITGROUP_STOMACH),
        [4] = initializeBodyPart('Левая рука', 'leftArmBleedTick', HITGROUP_LEFTARM),
        [5] = initializeBodyPart('Правая рука', 'rightArmBleedTick', HITGROUP_RIGHTARM),
        [6] = initializeBodyPart('Левая нога', 'leftLegBleedTick', HITGROUP_LEFTLEG),
        [7] = initializeBodyPart('Правая нога', 'rightLegBleedTick', HITGROUP_RIGHTLEG),
    }
end

function PLUGIN:initHealth()
    return { 
        bodyParts = getBodyParts(),
        heartRate = ix.config.Get('heartRate'),
        blood = ix.config.Get('blood'),
        highBP = ix.config.Get('bloodPressure'),
        cardiacOutput = ix.config.Get('cardiacOutput'),
        spo2 = ix.config.Get('spo2'),
        unconscious = false,
        heartAttack = false,
        bleedStatus = false,
        resistance = 100,
        pain = 0,
        bleed = 0,
        morphinCount = 0,
        adrenalinCount = 0,
        timers = {},
    }
end

ix.char.RegisterVar("healthStatus", {
    field = "healthStatus",
    default = PLUGIN:initHealth(),
    bNoDisplay = true
})
