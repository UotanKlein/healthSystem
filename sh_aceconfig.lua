local PLUGIN = PLUGIN

PLUGIN.aceConfig = {
    woundTypes = {
        abrasion = {
            bleeding = 0.001,
            pain = 0.4,
            description = "Also called scrapes, they occur when the skin is rubbed away by friction against another rough surface (e.g. rope burns and skinned knees)."
        },
        avulsion = {
            bleeding = 0.1,
            pain = 1.0,
            causeLimping = true,
            description = "Occur when an entire structure or part of it is forcibly pulled away, such as the loss of a permanent tooth or an ear lobe. Explosions, gunshots, and animal bites may cause avulsions."
        },
        contusion = {
            bleeding = 0,
            pain = 0.3,
            description = "Also called bruises, these are the result of a forceful trauma that injures an internal structure without breaking the skin. Blows to the chest, abdomen, or head with a blunt instrument (e.g. a football or a fist) can cause contusions."
        },
        crush = {
            bleeding = 0.05,
            pain = 0.8,
            causeLimping = true,
            causeFracture = true,
            description = "Occur when a heavy object falls onto a person, splitting the skin and shattering or tearing underlying structures."
        },
        cut = {
            bleeding = 0.01,
            pain = 0.1,
            description = "Slicing wounds made with a sharp instrument, leaving even edges. They may be as minimal as a paper cut or as significant as a surgical incision."
        },
        laceration = {
            bleeding = 0.05,
            pain = 0.2,
            description = "Also called tears, these are separating wounds that produce ragged edges. They are produced by a tremendous force against the body, either from an internal source as in childbirth, or from an external source like a punch."
        },
        velocityWound = {
            bleeding = 0.2,
            pain = 0.9,
            causeLimping = true,
            causeFracture = true,
            description = "Also called velocity wounds, they are caused by an object entering the body at a high speed, typically a bullet or small pieces of shrapnel."
        },
        punctureWound = {
            bleeding = 0.05,
            pain = 0.4,
            causeLimping = true,
            description = "Deep, narrow wounds produced by sharp objects such as nails, knives, and broken glass."
        },
        burn = {
            bleeding = 0,
            pain = 0.7,
            minDamage = 0,
            description = "Pain wound that is caused by making or being in contact with heat."
        }
    },
    damageTypes = {
        ['DMG_BULLET'] = {
            thresholds = {{20, 10}, {4.5, 2}, {3, 1}, {0, 1}},
            selectionSpecific = 1,
            damages = {
                avulsion = {
                    weighting = {{1, 1}, {0.35, 0}},
                },
                contusion = {
                    weighting = {{0.35, 0}, {0.35, 1}},
                    sizeMultiplier = 3.2,
                    painMultiplier = 2.2,
                },
                velocityWound = {
                    weighting = {{1, 0}, {1, 1}, {0.35, 1}, {0.35, 0}},
                    sizeMultiplier = 0.9,
                },
            }
        },
        ['DMG_BLAST'] = {
            thresholds = {{20, 15}, {8, 7}, {2, 3}, {1.2, 2}, {0.4, 1}, {0, 0}},
            selectionSpecific = 0,
            damages = {
                avulsion = {
                    weighting = {{1, 1}, {0.8, 0}},
                },
                cut = {
                    weighting = {{1.5, 0}, {0.35, 1}, {0, 0}},
                },
                contusion = {
                    weighting = {{0.5, 0}, {0.35, 5}},
                    sizeMultiplier = 2,
                    painMultiplier = 0.9,
                },
            }
        },
        ['DMG_VEHICLE'] = {
            thresholds = {{6, 15}, {4.5, 7}, {2, 2}, {0.8, 1}, {0.2, 1}, {0, 0}},
            selectionSpecific = 0,
            damages = {
                avulsion = {
                    weighting = {{1, 1}, {0.35, 0}},
                },
                contusion = {
                    weighting = {{0.35, 0}, {0.35, 5}},
                },
                velocityWound = {
                    weighting = {{1.5, 0}, {1.5, 5}, {0.35, 5}, {0.35, 0}},
                },
            },
        },
        ['DMG_FALL'] = {
            thresholds = {{8, 20}, {1, 1}, {0.2, 1}, {0.1, 0.7}, {0, 0.5}},
            selectionSpecific = 0,
            damages = {
                abrasion = {
                    weighting = {{0.4, 0}, {0.2, 5}, {0, 0}},
                    sizeMultiplier = 3,
                },
                contusion = {
                    weighting = {{0.4, 0}, {0.2, 5}},
                    sizeMultiplier = 3,
                },
                crush = {
                    weighting = {{0.4, 5}, {0.2, 0}},
                    sizeMultiplier = 1.5,
                },
            }
        },
        ['DMG_CRUSH'] = {
            thresholds = {{1.5, 3}, {1.5, 2}, {1, 2}, {1, 1}, {0.05, 1}},
            selectionSpecific = 0,
            damages = {
                abrasion = {
                    weighting = {{0.3, 0}, {0.3, 5}},
                },
                avulsion = {
                    weighting = {{0.01, 5}, {0.01, 0}},
                },
                contusion = {
                    weighting = {{0.35, 0}, {0.35, 5}},
                },
                crush = {
                    weighting = {{0.1, 5}, {0.1, 0}},
                },
                cut = {
                    weighting = {{0.1, 5}, {0.1, 0}},
                },
            }
        },
        ['DMG_RADIATION'] = {
            thresholds = {{0.1, 5}, {0.1, 0}},
            damages = {
                abrasion = {
                    weighting = {{0.3, 0}, {0.3, 5}},
                },
                cut = {
                    weighting = {{0.1, 5}, {0.1, 0}},
                },
                velocityWound = {
                    weighting = {{0.35, 5}, {0.35, 0}},
                },
            }
        },
    },
    medication = {
        maxDoseDeviation = 2, -- Количество доз, превышающих максимальную, при которых существует вероятность передозировки. Пример с максимальной дозой = 4 и отклонением от максимальной дозы = 2: Доза 4: безопасная | Дозы 5 и 6: Возможная передозировка | Доза 7: Гарантированная передозировка.
        morphine = {
            painReduce = 0.8, -- Насколько уменьшается боль?-
            hrIncreaseLow = {-10, -20}, -- heartRate < 55
            hrIncreaseNormal = {-10, -30}, -- 55 <= heartRate <= 110
            hrIncreaseHigh = {-10, -35}, -- 110 < heartRate
            timeInSystem = 1800, -- Как скоро это лекарство перестанет действовать
            timeTillMaxEffect = 30, -- Через какое время будет достигнут максимальный эффект
            maxDose = 4, -- Сколько лекарств этого типа может быть введено в организм пациента до того, как у него может возникнуть передозировка?
            incompatibleMedication = {},
            viscosityChange = -10,
        };
    },
}
