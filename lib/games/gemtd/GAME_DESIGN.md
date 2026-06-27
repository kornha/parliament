# GemTD — Game Design Doc

> Single source of truth for the city/ability/special design. We design the whole
> game here first; implementation happens in one pass against this doc.
>
> **Status legend:** ✅ locked · 🔧 in progress · ⬜ not started · ❓ open question

---

## Core mechanics (reference — how the game works today)

- **Cities = a region at a level (1–6).** Each region (`CityType`) has 6 cities.
- **Combine system:** two identical gems (same region + level) → one gem of the
  next level in that region. A maxed L6 = 32 L1 gems of combining.
- **Specials:** built from specific *named* cities via recipes in
  `game/game_constants.dart`. Only **Hanoi** (3× Phnom Penh) and **Volgograd**
  (St Petersburg + Moscow) are active today; the rest are commented out.
- **Each city** = a **shared regional ability** + (usually) one **unique ability**.
- **ROCK** = the maze block (no combat), raw material.

### Region base-stat profiles (current code)
| Region | Range | Atk speed | Damage | Notes |
|--------|-------|-----------|--------|-------|
| E. Europe | retune TBD | retune TBD | retune TBD | **single-target — Oligarchy/compound** |
| W. Europe | retune TBD | fast | low (shared) | **multi-target / share — Socialism** |
| E. Asia | 3.3→3.8 | `0.4+0.05·lvl` (slow) | `5.5+0.5·lvl` (high) | **single-target** (splash removed) |
| ASEAN | 3.0→4.0 (KL aura 0.8→1.3) | 0.85→1.1 | `1.7+0.5·lvl` | AoE |
| S. America | 2.5→2.9 | 0.4→0.9 | `1.75+0.8·lvl` | big AoE |
| S. Asia | 1.5→2.0 (short) | 1.2→2.2 (fast) | `0.85+0.4·lvl` | — |
| MENA | 1 | 0 | 0 | pure support (no attack) |
| N. America | — | — | `3.2+1.85·lvl` (highest) | single-target |

---

## Regional focuses (identities)

| Region | Focus | Status |
|--------|-------|--------|
| 🟡 E. Europe | **Oligarchy** — compound / accumulate (single-target escalation) | 🔧 |
| 🔵 W. Europe | **Socialism** — share the attack (multi-target / spread specialist) | 🔧 |
| 🔴 E. Asia | **Slow alpha-strike** + stun + chance-amplification | ⬜ |
| 🔵 ASEAN | **Armor break / vulnerability** | ✅ |
| 🔴 S. America | **Burn / DoT** stacking & spread | ⬜ |
| 🟢 S. Asia | **Poison + slow** control (differentiate from S. America) | ⬜ |
| 🟢 MENA | **Pure support / economy** (no direct damage) | ⬜ |
| ⚓ N. America | **High single-target DPS + high-variance RNG** | ⬜ |

Cross-region intent: ASEAN/MENA set up → E.Asia/N.America nuke → S.America/S.Asia
sustain → E.Europe/W.Europe control. (To be refined as we design each region.)

---

## 🔵 ASEAN — ✅ LOCKED

**Focus:** Armor break / vulnerability. **Shared:** `Allure` (−enemy armor,
`Lust` buff `[6,10,14,18,22,40]`) on all cities **except Kuala Lumpur** (which
can't attack — see below).

| Lvl | City | Country | Ability | Effect |
|----|------|---------|---------|--------|
| 1 | Phnom Penh | KH | *(Allure only)* | −armor |
| 2 | Ho Chi Minh | VN | Allure + **South & North** | Marks enemy; inert alone. + Hanoi's North & South → big armor drop |
| 3 | Manila | PH | Allure + **Thousand Islands** | ↑ attack speed, **attacks bounce**, ↑ projectile speed, **↓↓ damage**, **↓ range**, invisible projectile, random target |
| 4 | Jakarta | ID | Allure + **Thousand Islands** | (same) |
| 5 | Kuala Lumpur | MY | **Petronas** | Slow **aura** that applies **Oiled** (slow + amplified burn); **cannot attack** |
| 6 | Bangkok | TH | Allure + **Beautiful Chaos** | Huge range, random target, fast hidden projectile, **+ increased AoE + increased damage** *(rename of Full Moon)* |
| — | Hanoi *(3× Phnom Penh)* | VN | Allure + **North & South** | Marks enemy; inert alone. + HCM's South & North → big armor drop |

**South & North / North & South combo:** two complementary marks. Each does
nothing alone; when an enemy carries **both**, armor drops sharply (no separate
"Reunification" effect). Marks are short-lived (~1.5s) so both towers must keep
hitting the enemy → positioning puzzle. Reduction value tunable (~`[20,30,45,60,75,100]`).

**✅ KL — resolved:** Kuala Lumpur is a **pure slow aura, no Allure, cannot attack**.
It's the one exception to "Allure on all". Petronas = slow aura only (no armor cut).

**Implementation notes (reuse existing patterns):**
- Marks → `worksOnEnemies` + `buff`; conditional `armorModifier` like `Furnace`
  (buff.dart) checking `enemy.buffs.any((b) => b is OtherMark)`.
- Petronas aura → `canAttack=false` + `enemiesAura=true` like `Religion`.
- Thousand Islands → self-buff `{attackSpeed↑, damage↓↓, range↓}`;
  **bounce** reuses the existing chain mechanism (W. Europe `Luck of the Irish` /
  N. America `Brotherly Love` use `bf.ChainAttack`); random target via `onEnemyAttack`
  like `FullMoon`. With damage gutted it's a **debuff-spreader** — bounces Allure's
  armor-shred across a pack (on-theme).
- Invisible + fast projectile → per-city `GemAttributes` override like `BangkokSettings`
  (`projectilePath="weapon/empty_bullet.png"`, raise `projectileSpeed`). Asset exists.
- Beautiful Chaos → subclass `FullMoon` (keeps range buff + random target); add a
  self-buff `damageMultiplier↑` and bigger explosion (`explosionSizeX/Y↑` in its
  settings) for the +AoE/+damage. Leave `FullMoon` intact for Coinbase.

---

## 🟡 Eastern Europe — 🔧 IN PROGRESS

**Focus:** **Oligarchy** — *compound / accumulate*. Single-target escalation: each
sustained hit builds on the last (wealth/power compounds in few hands). The
ideological mirror of W. Europe's Socialism (hoard vs share), distinct from
N. America's Capitalism (Oligarchy = reliable accumulation; Capitalism = gambling).

> ⚠️ **Spine swapped.** EE was multi-target; that moved to W. Europe (Socialism).
> The old multi-target combo ideas (Moscow "hit all", Budapest ×2) are **retired**.
> `Perestroika` is **retired** (it was the multi-target shared ability).
> Cities below to be **redesigned around compound** when we reach EE.

**Shared ability — `Oligarchy`:** each consecutive hit on the *same* enemy **increases
attack speed** (reliably upward — the machine of capital accelerates). Single-target.
*This is the old W. Europe `Renaissance` mechanic reborn (kept as SPEED, not damage).*

**Cities** — derive uniques from the old W. Europe "subsequent-attack" family: each
**compounds a different effect** on sustained single-target fire, made *reliably upward*
(the old versions flipped ± randomly — drop that).

| Lvl | City | Ability | Effect | Status |
|----|------|---------|--------|--------|
| 1 | Kyiv 🇺🇦 | *(Oligarchy only)* | the speed ramp — foundation | ✅ |
| 2 | Budapest 🇭🇺 | **Thermal Baths** | compounding **slow** | ✅ |
| 3 | St Petersburg 🇷🇺 | **Leningrad** | compounding **bounty/money** | ✅ |
| 4 | Prague 🇨🇿 | **Defenestration** | compounding **armor shred** | ✅ |
| 5 | Warsaw 🇵🇱 | **Uprising** | compounding **vulnerability** (takes ever-more damage) | ✅ |
| 6 | Moscow 🇷🇺 | **Kremlin** | capstone: compounding **never resets** (permanent accumulation) | ✅ |
| — | **Volgograd** 🇷🇺 *(St Petersburg + Moscow)* | **Mother Russia** | does **more damage the lower your gold** | ✅ |

**Special — Volgograd / Mother Russia:** damage scales inversely with the player's gold
(broke = devastating). A comeback/clutch special, and a deliberate thematic counterpoint —
the region's cities *hoard* wealth (oligarchy), but Mother Russia is strongest in destitution
(Stalingrad / "Not One Step Back"). Distinct: nobody else scales off the player's gold.
Keeps the existing Volgograd recipe + gem (no swap needed).

**Derivation palette** (old W. Europe → made reliable): compound **vulnerability**
(Colosseum), compound **armor-shred** (Hooligans), compound **bounty/money**
(Couture — *the* oligarchy fantasy), compound **slow** (Flamenco).

*Old retired unique names (reusable): Kyiv Rus, Twin City, Leningrad, Defenestration,
Uprising, Central Command.*

---

## 🔵 Western Europe — 🔧 IN PROGRESS

**Focus:** **Socialism** — *share the attack*. The **spread-enemy specialist**
(inherits the multi-target mechanic; hits enemies AoE can't because they aren't
clustered). **Shared:** `Socialism` — each attack is shared across multiple enemies
(2→6 by level). *(Replaces the old single-target ramp; `Perestroika` retired.)*

**Roster ✅ locked** (dropped Milan + Madrid; added Brussels + Barcelona):

| Lvl | City | Country | Ability | Effect | Status |
|----|------|---------|---------|--------|--------|
| 1 | Manchester | 🇬🇧 | *(Socialism only)* | shares attack across enemies — the foundation (labour-movement roots) | ✅ |
| 2 | Dublin | 🇮🇪 | **Drunken Socialism** | attacks a *random* number of enemies per attack (**replaces** Socialism) | ✅ |
| 3 | Brussels | 🇧🇪 | **Bureaucracy** | attacks *every* enemy on the board, but **greatly reduced attack speed** | ✅ |
| 4 | Barcelona | 🇪🇸 | **Tiki-taka** | attacks **bounce / pass** to nearby enemies (share the ball) | ✅ |
| 5 | Rome | 🇮🇹 | **Gladiator** | chance to **execute** an enemy on hit (special crit / killing blow); cap so it can't one-shot bosses | ✅ |
| 6 | London | 🇬🇧 | **Seat of the Empire** | capstone: attacks *every* enemy on the board (global range), at full speed (no ramp) | ✅ |

**Brussels ↔ London pairing:** both hit the whole board — Brussels is slow & comprehensive (bureaucracy), London is comprehensive at *full speed* (empire). Difference is purely speed. (Drop Seat of the Empire's existing attack-speed ramp.)
*Both need **global/map-wide range*** (reuse Moscow's old `range = 15` pattern — freed now that EE is single-target Oligarchy).

**Art needed:** new coats of arms for **Brussels, Barcelona, Paris** (Manchester/Dublin/Rome/London already have them). Sourceable from Wikimedia, same as the EE set.

**Palette for L2–L5** (simple, distinct, on-theme):
- **Solidarity** — more enemies hit = more damage to each (strength in numbers).
- **Wider Share** — hits noticeably more enemies (amplifies Socialism).
- **Safety Net** — always also hits the enemy furthest along the path (catch leakers).

Differentiate from N. America (bounce): Socialism = one *simultaneous shared* hit,
not chained bounces.

**Special:** **Paris** 🇫🇷 — the Paris Commune (first socialist government).
**Ability: Revolution** — damage scales with the number of enemies on the board
(bigger mob → bigger uprising; clutch when swarmed). Distinct from EE Oligarchy
(which scales off *time*, not count). *Optional:* above an enemy-count threshold it
"boils over" into a one-time board-wide strike. **Recipe TBD** in the specials pass.
**Base roster stays Western/Southern Europe** — Germany + Scandinavia are reserved
for the future *Northern Europe* region.

## 🔴 East Asia — 🔧 IN PROGRESS

**Focus:** single-target, **slow + heavy** hits. **Shared:** **Balance** (chance to stun).
**Spine (dual):** stun-lock/control **+** Technology/Precision (chance-bending) — they
synergize: chance-bending makes the stuns/crits/reverses **reliable**. vs N. America:
E. Asia *engineers* its outcomes, doesn't gamble.

| Lvl | City | Ability | Effect | Status |
|----|------|---------|--------|--------|
| 1 | Osaka 🇯🇵 | *(Balance only)* | chance to stun — foundation | ✅ |
| 2 | Shenzhen 🇨🇳 | **Manufactured Technology** | this tower's chance effects (crit/stun) fire **highly reliably** | ✅ |
| 3 | Seoul 🇰🇷 | **K-Pop** | chance to make enemies **reverse direction** temporarily (walk backward along the path; reuse speed system — >100% slow = negative speed) | ✅ |
| 4 | Beijing 🇨🇳 | **The People's Republic** | aura: nearby towers' chance abilities trigger **far more often** (the amplifier) | ✅ |
| 5 | Shanghai 🇨🇳 | **Red Capitalism** | chance to **crit (big dmg) + stun** | ✅ |
| 6 | Tokyo 🇯🇵 | **Kaizen** | capstone: each kill **permanently increases this tower's damage** (continuous improvement; per-kill increment, tunable cap) | ✅ |
| — | **Hong Kong** 🇭🇰 *(special)* | **Already Tomorrow** | every attack hits **twice** (now + "tomorrow" — the echo from the future). Reuse `SequentialAttack` (attacksNum = 2). Recipe: Shenzhen + Shanghai | ✅ |
| — | *Pyongyang 🇰🇵 — deferred* | — | possible future 2nd special (recipe ← Seoul / N-vs-S Korea) | ⏸️ |

Old kit (raw material): Balance (stun), Manufactured Technology (100% procs), K-Pop
(−armor/+speed), Great Wall (+spd/−range), The People's Republic (×8 chance aura),
Red Capitalism (crit+stun).

## 🔴 South America — 🔧 IN PROGRESS

**Focus:** burn / DoT stacking & spread. **Shared:** **Burn** (damage over time).
**Stats:** slow attack speed, big AoE splash.

| Lvl | City | Country | Ability | Effect | Status |
|----|------|---------|---------|--------|--------|
| 1 | Lima | 🇵🇪 | *(Burn only)* | DoT — foundation | ✅ |
| 2 | Medellín | 🇨🇴 | **Cartel** | on kill, collect a bounty = **% of the slain enemy's max HP as gold** (cartel's cut; big targets pay more). Tunable % | ✅ |
| 3 | Caracas | 🇻🇪 | **Crude** | applies **Oiled** — slow + amplified burn damage (cross-region; see below) | ✅ |
| 4 | Rio de Janeiro | 🇧🇷 | **Redeemer** | when an enemy leaks, a chance it's **redeemed** — costs **no capital** (leak insurance). Chance scales by level; **does not stack** (global) | ✅ |
| 5 | Buenos Aires | 🇦🇷 | **Tango** | **pulls enemies together** into the strike (clusters them for the burn). Impl: true vortex if feasible, else path-constrained pull | ✅ |
| 6 | São Paulo | 🇧🇷 | **Inferno** | **burn aura** — sets all enemies in range ablaze; **cannot attack** (reuse Religion/Petronas `enemiesAura`+`canAttack=false`) | ✅ |
| — | **Galápagos** 🇪🇨 *(special)* | **Forced Evolution** | each round, **copies a random tower** (attack type + ability, any region's city) at **its own level**. No fixed baseline — full random transformation. Reuses the special-company `_base` delegation pattern (randomized per round). Recipe TBD | ✅ |

**Roster change:** Bogotá → Caracas (drops Colombia double, adds Venezuela). **Art needed:** Caracas coat of arms.
*Retired: Bloom (spread burn), Colombian Roast / Hyperinflation (Caracas went oil instead).*

**🛢️ Oiled (cross-region status):** applied by the three oil cities — **Petronas** (ASEAN/KL),
**Caracas** (SA), **Riyadh** (MENA). An *Oiled* enemy is **slowed** *and* **takes amplified burn
damage** (soaked in fuel). Payoff: oil with any of the three → ignite with SA's Burn → torch.
Impl: slow via existing `speedModifier`; burn-amp via the Burn DoT checking for Oiled (Furnace-style).

## 🟢 South Asia — ⬜
Focus: poison + slow control. **Currently underdeveloped** (only Colombo has a
unique; L2–6 are all Spice Route). Needs differentiation from S. America. To design.

## 🟢 MENA — 🔧 IN PROGRESS

**Spine:** pure **support** — **zero direct damage** (MENA never attacks; it only *amplifies*).
**Shared: Religion** = an **allied damage-buff aura** (the blessing — boosts nearby towers' damage).

| Lvl | City | Ability | Effect | Status |
|----|------|---------|--------|--------|
| 1 | Damascus 🇸🇾 | *(Religion only)* | the ally damage-buff blessing — foundation | ✅ |
| 2 | Beirut 🇱🇧 | **Cedars of Lebanon** | ally aura — **amplifies nearby towers' buffs** (a buff *multiplier*; the leverage/amplifier hub). Reuses `buffMultiplier`. *Not* a damage aura — it multiplies *other* buffs | ✅ |
| 3 | Cairo 🇪🇬 | **Sphinx** | chance to apply a **random debuff** (slow / armor / vulnerability / stun / oil…); the damage-amp lives in this pool | ✅ |
| 4 | Riyadh 🇸🇦 | **Black Gold** | applies cross-region **Oiled** (slow + amplified burn) | ✅ |
| 5 | Tel Aviv 🇮🇱 | **Startup Nation** | **the one-off attacker** (breaks MENA's no-attack rule) — VC gamble: each attack does **0 or a huge multiple** (boom-or-bust). Shares the *Venture Capitalism* mechanic with N. America (duplication OK) | ✅ |
| 6 | Dubai 🇦🇪 | **Burj Khalifa** | economy capstone — enemies in range yield much more **gold/bounty** (monument to Dubai's wealth) | ✅ |
| — | **Jerusalem** ⭐ *(special)* | **Holy Land** | **attack-speed aura** (in range, like Religion) — nearby towers fire far faster (pairs with Religion's damage; amplified by Cedars). Recipe TBD | ✅ |

*Reworked from the obscure originals: City of Jasmine's damage-amp → folded into Sphinx's
random pool; Damascus → L1; Beirut → L2 to keep Cedars; Sphinx no longer touches armor.*

## ⚓ North America — 🔧 IN PROGRESS

**Spine:** **high single-target DPS + high-variance RNG** (gambling/finance; highest base
damage). **Shared: Capitalism** (per-attack chance to ↑/↓ damage) — on every city **except San Francisco**
(Venture *is* the extreme damage-RNG version) and **Toronto** (the deliberate non-RNG outlier).
It stacks fine with Wall Street / Crypto / Hollywood — those are different axes (timing / speed / star).

| Lvl | City | Ability | Effect | Status |
|----|------|---------|--------|--------|
| 1 | Philadelphia 🇺🇸 | *(Capitalism only)* | foundation — birthplace of America | ✅ |
| 2 | Toronto 🇨🇦 | **Immigration** | elevated base damage that **decreases per nearby allied (non-Rock) tower** — strongest in isolation; wants space, not a crowd | ✅ |
| 3 | Miami 🇺🇸 | **Crypto** (pump-and-dump) **+ Capitalism** | reuses the freed **Caffeination** mechanic — fast burst (pump) then slow crash (dump). Keeps Capitalism (different axis: speed cycle vs damage ±) | ✅ |
| 4 | San Francisco 🇺🇸 | **Venture Capitalism** | 0 or a huge multiple (shared w/ Tel Aviv) | ✅ |
| 5 | Los Angeles 🇺🇸 | **Hollywood** | chance to turn an enemy into a **Star** — invulnerable & debuff-immune during stardom, then **dies** when it ends. A timed guaranteed kill (beats tanks), but the star keeps marching untouchable → can leak if starred near the exit (high-variance, on-spine). **Low % chance** (rises per level but stays low — a rare, powerful proc); duration scales too | ✅ |
| 6 | New York 🇺🇸 | **Wall Street** | random damage multiplier, rerolls every 3s | ✅ |
| — | **Washington DC** 🇺🇸 *(special)* | **Deep State** | total chaos — **invisible attacks** (no projectile), **random targets**, **random damage**, **variable attack speed**. The unpredictable hidden hand; peak RNG. **Visual: hidden projectile + bomb explosion on impact.** Reuses empty-bullet + FullMoon random-target + Wall Street RNG + a random speed mod. Recipe TBD | ✅ |

*Dropped Seattle; Miami → base city; Washington DC → special. (Note: L2 Toronto / L3 Miami = Tier 5 / Tier 4.) Bounce removed (→ W. Europe's Tiki-taka) — hit Philadelphia (L1), Toronto, LA.*

---

## 🦁 Africa — "The Wild" ✅ DESIGNED

**Spine:** **"The Wild" — each city *is* an animal/icon; NO shared ability.** Africa is the one
region with no universal mechanic — the cities are unified by *theme*, not a buff. Broadened from
strict wildlife to **"iconic Africa": wildlife + music + minerals.** Leans **anti-tank / big-game
hunter** (%HP) plus fresh mechanics (orbit, piercing-knockback, electrocute, capital-cost).

| Tier | City | Ability | Effect | Status |
|----|------|---------|--------|--------|
| 1 (capstone) | Cape Town 🇿🇦 | **Great White** | each hit deals a **% of the enemy's *current* HP** — huge bites on full/tanky enemies, diminishing as they drop; **can't kill** (a softener, not a finisher). Scales by level. Freed %HP family (current-HP variant) | ✅ |
| 2 | Nairobi 🇰🇪 | **Stampede** | a **straight, non-homing, piercing** charge (no explosion — passes through the whole column), **knocks all hit enemies back along the path**. **+damage, −attack speed** (slow heavy charge). New projectile behavior + reuse reverse-speed for knockback. *(Maasai Mara / Great Migration)* | ✅ |
| 3 | Johannesburg 🇿🇦 | **Hex** | chance to turn an enemy into a **frog** that **wanders in a random direction** for a few seconds, then reverts — a disorient (loses path progress + can't fight). Duration scales by level. Freed Serendipity | ✅ |
| 4 | Lagos 🇳🇬 | **Afrobeat** | the *beat*: **dramatically ↑ attack speed**, **tempo re-rolls randomly** (Wall Street, but on *speed*), **no projectile + very fast projectile speed**, **reduced damage** (machine-gun chip). **Custom drum/Afrobeats sound** on attack | ✅ |
| 5 | Kinshasa 🇨🇩 | **Cobalt** | **no attack** — an **AoE aura that electrocutes all enemies in range** (continuous electric damage) **but speeds them up** (the jolt — a negative slow). Risk/reward damage field. Reuses aura pattern + negative-speed; scales by level | ✅ |
| 6 (foundation) | Addis Ababa 🇪🇹 | **Vultures** | birds **orbit the tower**; enemies they pass through take damage (a spinning ring). New mechanic (orbiting projectile — moderate new code). Distinct from Cobalt (ring vs full-radius aura) — give them distinct visuals | ✅ |
| ⭐ special | **Sierra Leone** 🇸🇱 | **Blood Diamond** | dramatically **↑ damage + ↑ bounty**, **BUT drains your capital on every attack**. A Faustian engine — riches bought with blood. **First ability that costs the player capital.** Scales by level | ✅ |

*No shared ability (unique among regions). Two non-animal icons: Afrobeat (Lagos/music), Cobalt
(Kinshasa/minerals). **%max-HP** intentionally absent (dropped with the old "Lion King"). **Venom/poison
dropped** (slow-saturation + S. America burn overlap). Stampede moved Lagos→Nairobi; Shark→Great White;
Crocodile/Gorilla/Python considered & dropped for Cobalt. Audio pass: Lion roar / Great White chomp / Afrobeat drums.*

---

## Planned future regions
- **South Asia** (India/Pakistan/Bangladesh/Sri Lanka/Nepal) — *deferred* (was the 8th region;
  **replaced by Africa**). Underdeveloped, and its poison/slow spine overlapped S. America.
  Cities: **Mumbai, Delhi, Kathmandu, Dhaka, Islamabad, Colombo.** Needs a fresh distinct spine.
- **Northern Europe** (Germany + Scandinavia/Nordics) — a 9th `CityType`. Earmarked:
  **Berlin**, **Stockholm**. Spine TBD. *(W. Europe must not poach these.)*
- **Central America** (Mexico + the isthmus: Guatemala, Costa Rica, Panama…). Earmarked:
  **Mexico City**. Spine TBD. *(N. America keeps Miami; don't poach Mexico.)*

## ⭐ Specials & combos — ✅ DESIGNED

**Rule:** every one of the **48 base cities is used in exactly one** special recipe (8 specials ×
6 cities = 48). Combos are **thematic** and **typically cross-region**. Recipe = combine the listed
cities (exact quantities tunable at implementation).

| Special | Region | Theme | Combo (6 cities) |
|---------|--------|-------|------------------|
| **Jerusalem** (Holy Land) | MENA | **Faith** — the world's religions converge | Tel Aviv + Rome + Cairo + Addis Ababa + Manila + New York |
| **Hong Kong** (Already Tomorrow) | E. Asia | **Finance / trade** | Shanghai + Shenzhen + Tokyo + London + Dubai + Toronto |
| **Washington DC** (Deep State) | N. America | **Power / espionage / surveillance** | Beijing + Moscow + Prague + Brussels + Philadelphia + San Francisco |
| **Paris** (Revolution) | W. Europe | **Revolution / uprising** | Kyiv + Warsaw + Budapest + Barcelona + Buenos Aires + Seoul |
| **Volgograd** (Mother Russia) | E. Europe | **War / siege / resilience** | St Petersburg + Beirut + Damascus + Phnom Penh + Ho Chi Minh + Manchester |
| **Galápagos** (Forced Evolution) | S. America | **Nature / wildlife / biodiversity** | Lima + Nairobi + Cape Town + Jakarta + São Paulo + Rio |
| **Sierra Leone** (Blood Diamond) | Africa | **Resources / blood money** | Johannesburg + Kinshasa + Lagos + Medellín + Riyadh + Caracas |
| **Hanoi** (North & South) | ASEAN | **Nightlife / never-sleeps** *(loosest theme)* | Kuala Lumpur + Bangkok + Dublin + Osaka + Los Angeles + Miami |

*All 48 cities used exactly once; all 8 combos are cross-region. Jerusalem honors the NYC+Tel Aviv
idea (NYC = Jewish diaspora). **These replace the legacy in-code recipes** (Hanoi = 3×Phnom Penh,
Volgograd = St Pete + Moscow) at implementation. Hanoi's combo is the one loose/non-name-thematic
set — "cities that never sleep." Legacy disabled companies (BlackRock, AirBnB, Coinbase, FIFA, Fox
News, NBA, NFL, Tinder, Hard Rock, WhatsApp) are superseded by this special-per-region scheme.*

---

## Decisions log
- E. Europe shared ability renamed **Crossfire → Perestroika** (done in code).
- ASEAN spine = armor break; Allure on all cities except Kuala Lumpur (pure slow
  aura, cannot attack); full spec locked (above).
- E. Asia: **splash removed → single-target** (rebalances roster to 4 single / 3 area / 1 support).
- **Europe swap:** W. Europe = **Socialism** (multi-target / share), E. Europe =
  **Oligarchy** (compound / accumulate, single-target). `Perestroika` retired.
  Rationale: by contemporary politics W. Europe is the social-democratic side.
- **Bounce** = W. Europe's signature (Barcelona **Tiki-taka**). Remove from N. America
  (Brotherly Love/Hollywood) in its design pass. ASEAN Thousand Islands keeps bounce
  as a *debuff-spread tool* (❓ confirm).
- **Tier terminology:** cities & specials are shown by **Tier**, where **Tier 1 = most
  powerful (the capstone)** down to **Tier 6 = the foundation** — the *reverse* of level
  (Tier = 7 − level). Just sounds cooler. *(Tables here still use L1→L6 = foundation→capstone;
  relabel to Tier at implementation.)*
- Process: design entire game in this doc first, then implement in one pass.
