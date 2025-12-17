# RaiderCheck

![Version](https://img.shields.io/badge/version-2.0.0-green)
![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-blue)
![Server](https://img.shields.io/badge/server-Sirus-orange)

**RaiderCheck** — аддон для World of Warcraft 3.3.5a (Sirus), который позволяет рейд-лидерам и офицерам быстро проверить готовность группы к рейду.

## 🎯 Что делает аддон?

Сканирует всех игроков в группе/рейде и показывает:

- ⚔️ **Зачарования** — какие слоты не зачарованы
- 💎 **Камни** — пустые сокеты и качество вставленных камней
- 📚 **Таланты** — билд каждого игрока с возможностью детального просмотра
- 🛠️ **Профессии** — список профессий и их уровень
- ⚙️ **Проф. бонусы** — проверка использования профессиональных улучшений

## ✨ Особенности

- 🔄 **Автоматическое сканирование** при входе в группу/рейд
- 🎨 **Современный интерфейс** с цветовой индикацией проблем
- 👁️ **Детальный осмотр** снаряжения каждого игрока
- 🌳 **Визуальное дерево талантов** как в стандартном интерфейсе
- ⚡ **Работает только с игроками у которых есть аддон** — никаких багов Inspect API
- 📊 **Фильтры качества камней** — настройте минимальный уровень (БК/ЛК/РБК/НРБК и т.д.)
- 🔗 **WeakAuras совместимость** — standalone модуль для пользователей WA
- 🏗️ **Модульная архитектура** — чистый и поддерживаемый код

Код импорта в WeakAuras
```
!WA:2!nVZFVTXr2fB)hTG4aQRpGa008hB30CG8mTIS010lkvbGsMYMxLe5rszFgoomR4oKCpVAxIDxABLljiwoT5kCV4Cg565E5ItoNIE)XvGtHokw(hYgiFcgA0pbbOFbYNG(EZm7UZ(dsrPMwuzlrUZ(M3VM38M37nZCGfoYAhr)i6)8)wh7EEMgweNYRuFXslx82gnTTQz3ZPj5zFQNO1ZRJTt5UEg2wUz6RB421uB96Kl7P(8D7RP)t756r0xYW6GoRxUvlxI3b6Rz1e6tfBdlVvNV4Y1lwTRIuhB0Y2znnVgDB4zSgr80b6E4MaQSxdHyLU6AEKQKlsS8(QM22M62xYQOEBshhTMmo5fR66P54Lz1wgwgUDYmh8H3P7EyD7gC00ONLPTMENv5pE5x6)6yhtz29Wpza4RQzOtCMVdP5fuodr7cf65O5QSKTEptc(E6VLUnDh43hs3K(a62dUYGnG)(E0DgCn69uGMFe9lgCv6dg8pRq)c4JRhIgw))3GxUd9(d(hbCS9mk0pzW7a9)xsFOsLslFY8k0hbi8XqJBs7tVpDtelBc9aW)G)Hm7djIEd6wdENbxbOY1Nr54t8dMyswZ3eA6Xa3cCk9UWN9zKzB6watDdMyHCW2d2aLK(skdKRO3xzEMwwzEBDYEMTymak5BbshkW9rbEW)eG4TanbJV6dn)iO5DgC1bVVcxRZ0Am9oWYBIpn49Zy0sEulKp1S0t9ftGgogAMgVbrxXRdXkJc8JdXRNJvgILEMmPIUztNk2ok)S3k1EmXPlwTwPYld9uLP2v5Y9hbchQcrfpA1SL0qmDRmM2n1mvWzoeNtO5PbDhia2Ztqw1UNvtIcBWehH2cnd9TZIz5STYkvorH6fvyTTTctN9qOl7W(fS(ug8lq4aT92aepI3lF6dkcdR28PLal0sZ0LiEhhVnorX5kVYYZxeE70ka7bC1wGHnAE)fdUwM9PT6VJ(RGjj0pJ(X0Fd9FNEt6nvO3I(j0pL(ROFi87hr)JWF)TkaGFm9dO)E43pI(b7plWBfBQgibpc(3NdgICv09Y0cu4O7Nuh8NPgOLwI46Q1MKDn321xVljVcOX0YRa(QAt8YXST4QTw9mnfadQmb4ktmHI6mQ4hzXoI2tQQ8UX(dyDZrvOPk(ds5c662w(KxvIbvZltS8kQN5uLQvPyv1OSfbhs9riNhB2rZYIyc8x2ts8wU3AiwxIS2Qeh3S5uEfLjZXMxPwTqPtOYy2kfQw)SQ7pgtqob7at9yt)ygccVtO)07at1rB9WjmdExzVObtaEmaiZth8U7GtmESWfdy2JEtO93LXtqMl5rwRKEwd4JfnSUqo)bblBpf)gJouW9COyzygigHkudg6a9PFFNbw5RzNSQ4ZZK951pAoXOTan8oWve7kZw0c1GEFlYVeFmomwg440y7W(92G7UjvzwjHncgki9gpP6KOgWnRRPn018k7Dr7N9w5vMmIWjjHTzyN7vnSvpBpnZA2nVaXdF3KH9kXALGPhUiLWwbywj7peKRcrdWCFGnHo6FiZL79uYIFYDtFFWo9ASLCbdtLvkXLniUifdG6hpp4rv3o2CtGXxwBnywtBHOpRepeyaa6RCbDeuw(aJJh(FhhIuJQ58L0pjyk0drWvmr4h8ESzpF(GRjlJ8qdq6Qu6ebs6GRhbNH6C)jcT3L5br5Dr3sWRPGBWBfGEpBREO7QSbTNlrhLrn2RuXo(JN2QMeiEbxIJxwUHt(iDnjU9T4s7z)VhXQKR19vQIaGUp2alUYTyl03N(i(Qt333tMc7DO7T76BguZtdmE3vRmUAZLb8Sr7lAKi3qOBf)zWc1hV3r0BXMbLLbY5ulUuL6NTrTYZ)3xSEJQfpH65runzOI7OPd6zlU4ILpZ4c9ClUsXXf2LkwVW4cBLQLQTuH6LMpshIm(j854BDiRggh)DZBBAsAYu5Uy4EzZfB1djxvsVP0YNgsZQCvGtxSC9AimbYI6PiA61aVNQ5dBBzGQXBRwh7EMalfV950sclW2UEXB8mogjB8uGvKBci1sbYfjTta4cesc4waIeL4mz6nF84nx3bmyjEtoK2ta)sAgwipNq7qGSI11CwpTxwvdOTCRsJqOB8g5vW1Vqh2kgWQ6D1mGiOInQLlPtE(IEI5Lwy2W2oRJKPKvl7S(OmxSEfSAy0(vs0CwvE6eQ5f4pS)YlvK(AQPhBGlXS1OIajj)fPBPgLvs)6XNqjHHrgKqcPlIqazSQl0wbH402T3QzHaXHGLFB1rGKiRiKCHfC(A(en76bMETNGx2JSPUsJ6ZRpZZ7Y(V4lQ5tfqHaN67eQzmQ8jhs3Jes2qHkIoh97LFelpcZsAQfU8OAE1C7gl4pcK49r185g9kNcpVr4c(iGI6lddIJV336AMWmMK(F9Cie3WKWJmdhiBjlDYLhA8AqCic8YNwUCWZz97B85XE83JZ1dPyeBqoLrOKiUeLK4cjoHf2iwKpy6KbXbs8Y2S3AWtoA(onQlqk4LXN7YltP0MII9(0Ay2Im8GgkdFYIKSfbXSmGFBwgWc8LCypIkikw9hHYh1oic1qtYCJN9Je(uFZ9Knufh7wqETyPktyh1n67IN8bm(v7cgMMHgkShHzie3S5IA2zemKl6sYLqW25zky4IHcGd4gUfVCxyDmc4RKbaSa2f4woK16YkCRR4nlzRB0IzLWFu7YCynClSkGbBluFPmBavbooGDz2pgPV8saFXcZKLeNG9ynef9ylYKpzdVIYXtUqveBJyA98X8dRkC2QRMxwNfOD4o(IsuwmG7d3sjyLX1bfwoLYxYIzrLSKs8L1z60zvwXYGfCqWQ9rsywc0uszEyjlB4hwQ)kVJmCvVq3OXGFyoytoXqUxPpLko7vrZXtkizCssxOjwyx(S5mTfPBEUx7Lp)rvJe4veBMqmMNHLCJuZmVDplpG0pxy3Kfo45JxZ4nyL7tZRZenjgMzL64lOmDUyWpvc4L7WXcXzoO3tLUc54X9VWADQuBD6uwzt4IrIUsAlmorL)UzLeUrpjKZr5LgQoNX5LMbz6ssIYJkPlgd0p1ir)U05PhENtB2nZ(uUUVQLQxCPAhxnFkbICC(e9OLDDiyyQuXWu7bmmDQyy6Xdd1lSiKAsn18YZI3TovPA5fkwd3KdSJjCYj3z2Fc3vJZf6p68rsE1pL3GPU5LMO6hnLmlg8AjYdGeNzcXIXAqMSAR1ve3d8y2C(5Wfu)54BnG)EP0xHENbVZGRsFm86RQKTBp3ohJVRF8kuNBmCOZ3vfH7m)Tcd3)fCJ6UoRcq8sUPqFiwZnzIs3kAGdirccBis16JchAEVEaGSNIcjUoHp6Mvzs(I0b9dBzSw3iUY7bcbkqbY2MOhMQqL0aJ3lCbA4v(BOwUOu73XO0DHrJi7aMpHb61huUBhDx2Iqo)fyZfo()RbyFm9b89evm6SjFVqJSnBavfs2GROOl2GUDZeOzhcUFYrmda1F09ClTcBJC2Nr)sS(E3nnge((JsoKeFV88C6r296BpFdCQHJcwbsSwKkSTQ9kGoahY2IUtE(MYUjwisLYwC07ll(9gTIeFFIcT8GwIixrEv2yBSiUzrC9y2K1zn9nOmouJ3uqHglLDfduolOzAUQwZlixW1isRu8pOSSGdpCS5DiaeSNYQY(qnE6EetTUUe9G9BW39ehhaF6vRPJrxiuvFcQkPtqZ38GnNPNwkLHoa1(F7OCqtRy4(G8kZMyVDhAPXftEsJdTmmZLAFgVXS9242qQZEYTuSqLsX23WDFNOQeSEv2W1RISVxPVI2yUrxfmnLOWqW74UPzo296MMV)14TLAvK391pKwv4vIVeq00rzWm0YpWjbctvBxyUE8ef9PvI8tsnWnHmLNbFUDF)wsUr3JZkIdNSjt1k3q0kCImk1IeUqyzfc5)ZumPK3QafJPz3PbqdDqlqH8I1JdEk5k18I2A6e9Oiu(uz92ZgUvY7NJyYTO)s6Ns)a4V3IEB6VNEt6VbpmjyZ)bOHBs)xvYclf6F0b2kiqc6hsVfFt4URiucChEbxkiG3dpjo527hdf)JgIq9u2Qiw7EHVD2PHlpyqmrWKrwty4yQZFQc1BSuTt2OWjor5LJTDU(zxtAzC58WqQ48wOBGLaz1EiTWyQSWIVmlsGuRydV)STlw(qCK0oukyW4MAyHFe0jTsuSNWvmXlYjUbZzMlM(7S8RL9CV2mN)O5Mj7eF)C)1Qr2vCSIi(NaN9fhad0451dYiNzPicENFG92rC0aFp(rai8ibEDzwWN84yjIQHSH8PflDLYaLH4nX4Vg8UStj3d5hho25mqK7WGFb7JZuiYPsmZyTmBygEaPGL0h55BdlG7XUKMQVfvUDv1vT4pELI1QJApwCSOgeLh5J64quvIUMI2AxRF24YDIa6bM7lyjOChq7DpuzFh2i99LpkDBtFqkhJomZq(XUl4SIY8GSfIRijIKByYPiZN0nk(WqeioEF4W7GnuyHQZouLSCidcyLxJIxyQxy68kIm9ZRiL9Eck8X8dFGp)(iE6bmFEbhfl(R2ctcHNze7GhSdOX(YGergLEw6ypWvLBfXcGLPv4yW2d3MqubgS6SjAEQ0BE6u0SrQuklKoUfZ5tFH3uGdIXkEnjvERmJ64HmuAoHeEgtYprALdDyeooxKM(CVt3ZDCujG(JJsCEv(sBWzFqJP2t0y69fnMoDAmALyM9IEkcWyAY7MqVh7W0r7Wiobv4rYSKuH(3tCo(dUaWlRMwZ7jz6)jOA6Zp2dWyINYs8EEML)5GASSksbzPwbYmJWo2V2S)VKlRr7OinbiOqSjMH8TH4kxv5))IihT4YFli2sPMgjS(klw4SfR2aIYPuLLGr9gqC(lFYI8dBDiyfMVEPtxSb3YOXjRwELkHqgrrGrQgVi1ZOalP23pqHWmCKlTnEGph3lnWlWUTiSIrkoN1JoOS0kaQCTA2Zj1DtiGLBYUUa41b4M0Fn8j(0FeIdRpgv0MmXxCYk3bcvER8SZYkpGjrzPHyoIuHO7LB)DVc(uwGtSROb7298oIsQYtQeIyFBGaxHDXviTnWYHWoX8v4PBfm61fCoBMnfqYhnFmPYw)zSaOcl9noUWoeO3tkrvPs6YoDPqsbd5o0mrlNi1Dy4WmZkwo(mQPjljw)YOmIofP(HSojx(WrWrrRbaK(UFs5m18oSRpuuHoZiXwQfRLRrfxfQD4zGbdD99jdEIOXeZ(CmqvmBpm1GD45ZaJapKDXLYkBrH1l4Q863hPcdSjxBIwHxBWpNU1FvUm7vLM4B5gTbiR6fFoqe8oRD9rreFRoE5iIxSHC7HUouhA7fKmk3Dcz(tyUY2s(muVjpxT4xCm5TlHDT9YSRxtmXMMKPRJHL4e8P(MnxyHjNe)nvNCVPJYf5bYabVmQ8N9HrLNmm3h8xIMek4u07W2Wj8eFdstO9gDl1mGKpKjUPxsnjxlm5ymeb5kVH2oSn8jGbrxp(1wvcLlSWl9sJjk5Nv944fM1ekO8tVoo9JPh2Hnod)nh3X3ncUaOV(xX)SSfkWh8RdVzOS7f6gEogTBtCCF)VNJ4R)lZ5bbDq)UFTBVvzRTwRxlW)A)gZxOw9g1QxOAD63z1tr0m96ead3hC1AvkU4I0V7bRILA1nZC9aZLv5XbSHBxceGPUBMBRtwfqjgAJZPkUyLfwzXB0ZsqD2DR9NYk93fjtPzTE3JiUqS83VODBJMhjt3)CngeIwxYwN8F8uD)lt961Y)svm2d9VbgpiowAMIA0(h(AiiM2oqum8R673)zFQdUXLSD0pJJw3noJ4loxwCNEbw3vZdg08iDMRLTLx3dVGJXBO8J7PP7GjkuV(Tbvcorfck6zEA6Z8e4rCNYA7y3ZsF1oeJ2D8UYC45o81NdhcwyvEKJpD116z6zKzoqp18PPVCMQnn1CDXVnNlmFd)Yg(xc4xV7H75skiU2Xe9L0UCNnq(bpDi)f(xp5sar6MTekXT0AsEv8z3xTgoo04u2MR3OI9Ly76qpuvCdS(Q8BR8CLRxV8spXTJgqSFcx2pu1M2M2o)Odb)eN6gwDUTdtMXbv6pCQEg69RVY8L)rzpTZp08f)MlqiDlGcMxvnpd7ovVKHUxNRuvZSBhTdfE)P1U8b7(Cd)os31H00a51dDdnlJ1quz9I0)Sf(kIMlPMNdXQTxN)e6ZmNLTf5j644eard0E2XLDY1D3abLXL1MBnndRfOvHoqRrRtxHEA4ZdhVLUhD4mK(6GHUrZgEDatOoWyZ6Z9g22RDahuEmAT(ClwCH632ZU5f5MB)Px8vvn0FISxGcD)Edh)MK2AnxVrltBBNo9zRcaIjyODOVHF7YzllJIZQ1MVAXIllgZolFm7zFQvbHULr7mGFiKfiD(ATEWKjqV08m4qWCfGh7Z708SX3dCGdCOBJQkdXDD3WIZtWtzUnmjNOZ657(DoI7Q)ntm1Kt8doYf)p)j)3)
```

## 📸 Скриншоты

<img width="628" height="488" alt="image" src="https://github.com/user-attachments/assets/2c088b3d-279b-4403-a803-64fa5fffe343" />
<img width="212" height="453" alt="image" src="https://github.com/user-attachments/assets/1e35e45e-45d1-4e07-9a63-8de4990f68d4" />
<img width="463" height="479" alt="image" src="https://github.com/user-attachments/assets/e9162e63-2b49-4b92-9f64-aef60383c17c" />


## 📦 Установка

1. Скачайте последнюю версию из [Releases](https://github.com/Smotree/RaiderCheck/releases)
2. Распакуйте папку `RaiderCheck` в `World of Warcraft/Interface/AddOns/`
3. Перезапустите игру или введите `/reload`

### Структура папки
```
Interface/AddOns/RaiderCheck/
├── data/
│   ├── constants.lua        # Константы и настройки
│   ├── items.lua            # Парсинг предметов
│   └── settings.lua         # Управление настройками
├── logic/
│   ├── gear_analysis.lua    # Анализ экипировки
│   └── talents.lua          # Обработка талантов
├── core/
│   ├── init.lua             # Инициализация аддона
│   └── comm.lua             # Сетевое взаимодействие
├── ui/
│   ├── gui.lua              # Главное окно
│   ├── inspect.lua          # Окно инспекции
│   ├── talents_inspect.lua  # Дерево талантов
│   └── error_report.lua     # Отчёт об ошибках
├── GemsEnchantMapping.lua   # База данных камней и чаров
├── TalentsDatabase.lua      # База данных талантов
├── RaiderCheckWeakAuras.lua # WeakAuras модуль
└── RaiderCheck.toc
```

## 🎮 Использование

### Команды
| Команда | Описание |
|---------|----------|
| `/rc` или `/raidercheck` | Открыть/закрыть главное окно |
| `/rc show` | Показать окно |
| `/rc check` | Сканировать группу/рейд |
| `/rc talents` | Посмотреть свои таланты |
| `/rc report` | Показать неизвестные камни |
| `/rc debug` | Включить/выключить режим отладки |
| `/rc help` | Справка по командам |

### Интерфейс

1. **Главное окно** — список всех игроков с индикаторами проблем
2. **Клик по игроку** — открывает детальный осмотр снаряжения
3. **Клик по талантам** — открывает визуальное дерево талантов
4. **Настройки камней** — выбор минимального качества в главном окне

### Цветовая индикация

- 🟢 **Зелёный** — всё в порядке
- 🟡 **Жёлтый** — есть предупреждения (низкокачественные камни)
- 🔴 **Красный** — критические проблемы (пустые сокеты, нет энчантов)

## 🔧 Проверки профессий

Аддон автоматически проверяет использование профессиональных бонусов:

| Профессия | Что проверяется |
|-----------|-----------------|
| Кузнечное дело | Дополнительные сокеты на руках и запястьях |
| Ювелирное дело | 3 камня Dragon's Eye |
| Кожевничество | Fur Lining на запястьях |
| Начертание | Master's Inscription на плечах |
| Наложение чар | Энчанты на кольцах (400+ skill) |
| Инженерия | Усиления на перчатках/поясе/ботах |
| Портняжное дело | Вышивка на плаще |

## 📋 Качество камней

Система классификации камней:

| Тип | Описание |
|-----|----------|
| БК | Burning Crusade (устаревшие) |
| ЛК | Lich King (базовые WotLK) |
| РБК | Расширенные БК (зелёные WotLK) |
| РБК+ | Улучшенные РБК |
| НРБК | Новые РБК (синие) |
| ННРБК | Новейшие НРБК (эпические) |
| Донатные | Магазинные камни |

## 🤝 WeakAuras модуль

Для пользователей без основного аддона доступен standalone модуль:

1. Скопируйте содержимое `RaiderCheckWeakAuras.lua`
2. Создайте WeakAura типа "Custom" → "Every Frame"
3. Вставьте код в секцию Actions → On Init

Модуль автоматически отвечает на запросы от игроков с полным аддоном.

## ⚠️ Важно

- Аддон работает **только** с игроками, у которых установлен RaiderCheck или WA-модуль
- Это сделано намеренно из-за багов Inspect API на Sirus
- Для корректной работы рекомендуется установить аддон всем членам рейда

## 🐛 Известные ограничения

- Данные доступны только от игроков с аддоном
- Некоторые камни могут отсутствовать в базе данных
- Таланты отображаются только для стандартных WotLK классов

## 📝 Changelog

### v2.0.0 — Полный рефакторинг
- 🏗️ **Новая модульная архитектура** — разделение на data/logic/core/ui слои
- 🧹 **Единый источник истины** — вся логика анализа в одном месте
- 🔧 **Нет дублирования кода** — UI только отображает, не анализирует
- ⚡ **Улучшенная производительность** — оптимизированный парсинг данных
- 🐛 **Исправлены обработчики событий** — корректная работа CHAT_MSG_ADDON
- 📦 **Чистая структура проекта** — старые файлы в папке outupdate/

### v1.4.0
- Push-модель обновлений при смене экипировки
- Debounce система для сетевых сообщений
- Улучшенная обработка новых игроков в группе

### v1.3.0
- Объединены модули GemSettings и Professions в Items
- Удалён неработающий NativeInspect модуль
- Исправлен баг с JEWELCRAFTING_GEMS
- Оптимизация кэширования GetItemStats

### v1.2.0
- Новая система классификации камней
- Визуальное дерево талантов
- WeakAuras совместимость

### v1.1.0
- Первый публичный релиз

## 📄 Лицензия

MIT License — свободное использование и модификация.

## 👤 Автор

**Smotree** — [GitHub](https://github.com/Smotree)

Discord: @smotree

---

*Если аддон был полезен, поставьте ⭐ на GitHub!*
