ix.config.Add("bleedingDelay", 1, "Частота потери крови", nil, {
	data = {min = 0, max = 1000},
	category = "HealthSystem"
})

ix.config.Add("fracturesChance", 80, "Шанс сломать конечность", nil, {
	data = {min = 0, max = 100},
	category = "HealthSystem"
})

ix.config.Add("blood", 6.0, "Количество крови в организме", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("legSlowEffect", 30, "Эффект замедления, если нога сломана", nil, {
	data = {min = 0, max = 100},
	category = "HealthSystem"
})

ix.config.Add("fallBreak", 200, "Высота ломания конечности при падении", nil, {
	data = {min = 0, max = 1000},
	category = "HealthSystem"
})

ix.config.Add("damageFallHeight", 150, "Высота получения урона при падении", nil, {
	data = {min = 0, max = 1000},
	category = "HealthSystem"
})

ix.config.Add("fatalFallHeight", 400, "Высота смерти при падении", nil, {
	data = {min = 0, max = 1000},
	category = "HealthSystem"
})

ix.config.Add("handShakeIntensity", 1.0, "Интенсивность тряски рук", nil, {
	data = {min = 0, max = 1000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("handShakeSpeed", 1.0, "Скорость тряски рук", nil, {
	data = {min = 0, max = 1000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("screenShakeIntensity", 1.0, "Интенсивность тряски камеры", nil, {
	data = {min = 0, max = 1000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("screenShakeSpeed", 1.0, "Скорость тряски камеры", nil, {
	data = {min = 0, max = 1000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("moderateBloodLoss", (ix.config.Get("blood") * 0.85), "Количество крови для умеренной потери крови", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("severeBloodLoss", (ix.config.Get("blood") * 0.7), "Количество крови для тяжелой потери крови", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("criticalBloodLoss", (ix.config.Get("blood") * 0.6), "Количество крови для критической потери крови", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("bloodLossUnconscious", (ix.config.Get("blood") * 0.5), "Количество потеренной крови для потери сознания", nil, {
	data = {min = 0, max = 10000},
	category = "HealthSystem"
})

ix.config.Add("heartAttackBlood", (ix.config.Get("blood") * 0.3), "Количество потеренной крови для сердечного приступа", nil, {
	data = {min = 0, max = 10000},
	category = "HealthSystem"
})

ix.config.Add("unconsciousOn", true, "Включена ли потеря сознания", nil, {
	category = "HealthSystem"
})

ix.config.Add("pain", 1.0, "Максимальная боль", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("moderatePain", ix.config.Get("pain") / 5, "Обычная боль", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("painThresholdUnconscious", ix.config.Get("pain") * 0.5, "Сила боли для болевого шога", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("mildBleeding", (ix.config.Get("bloodLossUnconscious") * (1 / 5)) / 60, "Легкое кровотечение", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("moderateBleeding", (ix.config.Get("bloodLossUnconscious") * (1 / 2)) / 60, "Умеренное кровотечение", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("criticalBleeding", ix.config.Get("bloodLossUnconscious") / 60, "Сильное кровотечение", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("healthInfoUpdateDelay", 1.0, "Частота обновления состояния здоровья", nil, {
    data = {min = 0, max = 10000, decimals = 1},
    category = "HealthSystem"
})

ix.config.Add("leftArmShakeFactor", 1.0, "Модификатор тряски рук, если левая рука сломана", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("rightArmShakeFactor", 1.0, "Модификатор тряски рук, если правая рука сломана", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("stripWeaponChance", 5.0, "Шанс потерять оружие при получении урона в руку", nil, {
	data = {min = 0, max = 100, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("heartRate", 80, "Нормальная частота сердечных сокращений", nil, {
	data = {min = 0, max = 500},
	category = "HealthSystem"
})

ix.config.Add("bloodPressure", 120, "Нормальное давление крови", nil, {
	data = {min = 0, max = 500},
	category = "HealthSystem"
})

ix.config.Add("worstDamage", 20.0, "Худший урон", nil, {
	data = {min = 0, max = 500, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("bleedMultiple", 1.0, "Модификатор кровотечения", nil, {
	data = {min = 0, max = 500, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("painMultiple", 1.0, "Модификатор боли", nil, {
	data = {min = 0, max = 500, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("painFadeTime", 900, "Время длительности боли", nil, {
	data = {min = 0, max = 10000},
	category = "HealthSystem"
})

ix.config.Add("painSuppressionFadeTime", 1800, "Время длительности морфина", nil, {
	data = {min = 0, max = 10000},
	category = "HealthSystem"
})

ix.config.Add("durationheartAttack", 300, "Время остановки сердца до смерти", nil, {
	data = {min = 0, max = 10000},
	category = "HealthSystem"
})

ix.config.Add("checkAwakening", 15.0, "Частота проверки шанса пробуждения", nil, {
	data = {min = 0, max = 500, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("checkUnconscious", 15.0, "Частота проверки шанса потери сознания", nil, {
	data = {min = 0, max = 500, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("checkheartAttack", 15.0, "Частота проверки шанса сердечного приступа", nil, {
	data = {min = 0, max = 500, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("chanceWakeUp", 5.0, "Шанс проснуться", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("heartAttackChance", 5.0, "Шанс попадания в сердце", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("chanceLoseConsciousness", 10.0, "Шанс потерять сознание", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("increasingAdrenalineChanceWakeUp", 1.0, "Повышения адреналина шанса очнуться", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("headFatalDamage", 1.0, "Фатальный урон в голову", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("organFatalDamage", 0.6, "Фатальный урон в торс", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("cardiacOutput", 5000, "Сердечный выход", nil, {
	data = {min = 0, max = 10000},
	category = "HealthSystem"
})

ix.config.Add("bleedMultiplier", 1.0, "Модификатор кровотечения", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("painMultiplier", 1.0, "Модификатор боли", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("chestBrokenModifier", 0.5, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("spo2", 97, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("bleedTrackerTick", 1.0, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("healthStateCheckInterval", 1.0, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("healthStateCheckInterval", 1.0, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("weibullFatalDamageL", 6.5625, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("weibullFatalDamageK", 0.7045, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("damageThreshold", 3.5, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("PENETRATION_THRESHOLD", 0.35, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("deathRagdollRemoveDelay", 60.0, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("damageMultiply", 0.1, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("maxDoseDeviation", 2, "Количество доз, превышающих максимальную дозу, при которой существует вероятность передозировки. Пример с максимальной дозой = 4 и отклонением от максимальной дозы = 2: Доза 4: безопасная | Дозы 5 и 6: Возможная передозировка | Доза 7: Гарантированная передозировка", nil, {
	data = {min = 0, max = 10000},
	category = "HealthSystem"
})

ix.config.Add("hightHeartRate", 110.0, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("lowHeartRate", 55.0, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})

ix.config.Add("minFatalHeartRate", 40, "", nil, {
	data = {min = 0, max = 10000 },
	category = "HealthSystem"
})

ix.config.Add("maxFatalHeartRate", 180, "", nil, {
	data = {min = 0, max = 10000 },
	category = "HealthSystem"
})

ix.config.Add("heartHitChance", 5.0, "", nil, {
	data = {min = 0, max = 10000, decimals = 1},
	category = "HealthSystem"
})
