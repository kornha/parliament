# GemTD — Country Reframe (working notes)

Towers become **countries** (flags on the board). Each region has a **spine** (a
mechanic every tower shares); tier 1 is the basic version, the tier-6 **capstone**
perfects it. **Specials are countries too**, built from a **cross-region** recipe
(recipes are decided LAST).

**Reserved for a future Central Europe region:** 🇩🇪 Germany, 🇳🇱 Netherlands.

---

## 🟥 E. Europe — LOCKED
**Spine — Oligarchy:** focus a target → attack speed compounds (every tower).

| Tier | Nation | Ability | Effect (on top of spine) |
|--|--|--|--|
|1|🇱🇻 Latvia|*spine only*|—|
|2|🇭🇺 Hungary|Thermal Baths|compounding slow|
|3|🇨🇿 Czechia|Defenestration|compounding armor shred|
|4|🇺🇦 Ukraine|Wheat & Sky|small flat **gold per attack** (scales w/ fire rate, not stacks) — *NEW mechanic*|
|5|🇵🇱 Poland|Uprising|compounding **self-damage** (capped, resets on switch)|
|6|🇷🇺 Russia|Mother Russia|the spine (compounding attack speed) **resets only on kill**, not on losing focus *(capstone)*|
|★|🇭🇷 Croatia|Checkered Past|permanently gains **attack speed** per kill (soft-capped ~2–3×) *(special)*|

## 🟦 W. Europe — LOCKED
**Spine — Socialism:** every attack is shared across multiple enemies (every tower).

| Tier | Nation | Ability | Effect |
|--|--|--|--|
|1|🇮🇪 Ireland|Drunken Socialism|share to a random number of enemies|
|2|🇪🇸 Spain|Tiki-taka|attacks bounce|
|3|🇮🇹 Italy|Gladiator|chance to execute wounded|
|4|🇵🇹 Portugal|Age of Discovery|**global range, reduced damage**|
|5|🇫🇷 France|Revolution|more enemies on field → more damage|
|6|🇬🇧 UK|Seat of the Empire|whole board, full speed *(capstone)*|
|★|🇧🇪 Belgium|Bureaucracy|whole board, slowly *(special)*|

*Three "whole-board" towers, each nerfed differently: Portugal (weak dmg), Belgium (slow), UK (full).*

## 🟨 E. Asia — LOCKED
**Spine — Fortune:** every tower has a **chance to stun** on hit (the baseline
gamble); the region's identity is manipulating those odds — guarantee them
(Taiwan), multiply them (China). Spine is loose — K-Pop/Kaizen sit off it.
⚠️ balance: cap stun (diminishing returns / immunity window) so Taiwan×China
can't perma-lock the board.

| Tier | Nation | Ability | Effect |
|--|--|--|--|
|1|🇲🇳 Mongolia|*spine only*|— (the bare chance-to-stun)|
|2|🇹🇼 Taiwan|Semiconductors|all chance abilities proc 100%|
|3|🇭🇰 Hong Kong|Already Tomorrow|every attack strikes twice|
|4|🇰🇷 S. Korea|K-Pop|armor down + speeds enemy up *(off-spine, fine)*|
|5|🇯🇵 Japan|Kaizen|permanent **damage** per kill|
|6|🇨🇳 China|People's Republic|aura: nearby proc chance ×8 *(capstone)*|
|★|🇰🇵 North Korea|Juche|receives **no auras**, **off-spine**; attack = very slow missile, **huge explosion radius + atomic damage** *(special)*|

---

## 🟫 MENA — LOCKED
**Spine — Religion:** every tower buffs nearby allies' damage (support region).
Includes North Africa (Morocco, Egypt) — not split off. Turkey/Iran not used.
Cedars (amplify-buffs) removed.

| Tier | Nation | Ability | Effect |
|--|--|--|--|
|1|🇱🇧 Lebanon|*spine only*|pure Religion (buff nearby allies' damage)|
|2|🇲🇦 Morocco|Sandstorm|periodic AoE **damage** (no slow — MENA's area-damage tower)|
|3|🇪🇬 Egypt|Sphinx|chance to curse enemies|
|4|🇸🇦 Saudi Arabia|Black Gold|oil — slow + amplify damage taken|
|5|🇦🇪 UAE|Burj Khalifa|bounty aura — enemies in range yield much more gold (the "Golden Souk" mechanic, original name)|
|6|🇮🇱 Israel|Light unto the Nations|board-wide ally buff *(capstone)*|
|★|🇶🇦 Qatar|Propaganda|aura: sets nearby allied towers to **Qatar's exact tier** (up *or* down — homogenizing) *(special)* — NEW mechanic: effective-level override in `computeGemStatus`|

## 🟪 N. America — LOCKED
**Spine — Capitalism:** every tower's damage swings (boom/bust RNG) — the casino region.

| Tier | Nation | Ability | Effect |
|--|--|--|--|
|1|🇨🇺 Cuba|Viva la Revolución|reduced bounty + reduced damage, but attacks **bounce** (socialism in the capitalist region)|
|2|🇯🇲 Jamaica|Feel Good Man|chill aura — slows nearby **enemies** AND nearby **allies'** attack speed (double-edged)|
|3|🇵🇦 Panama|Tax Haven|*spine only* — pure Capitalism RNG|
|4|🇨🇦 Canada|Immigration|high dmg, less per nearby ally|
|5|🇲🇽 Mexico|Cartel|enemies worth more bounty (Colombia/S.America → "Cocaine" instead, to avoid dup)|
|6|🇺🇸 USA|Deep State|invisible attacks, random targets, random damage — + Capitalism spine *(capstone)*|
|★|🇸🇻 El Salvador|CECOT|chance to **imprison** (instantly remove) an enemy — **no bounty** *(special)*|

## 🟧 S. America — LOCKED
**Spine — Burn (DoT):** everything's on fire (the rainforest region).

| Tier | Nation | Ability | Effect |
|--|--|--|--|
|1|🇵🇪 Peru|Inti (Sun)|burn DoT — the spine|
|2|🇨🇱 Chile|Inferno|burn aura (Chilean wildfires) — freed when Brazil took Redeemer|
|3|🇨🇴 Colombia|Cocaine|**extreme Caffeination** — bigger burst, harder crash|
|4|🇻🇪 Venezuela|Crude|oil that **amplifies burn damage** (no slow) — combos w/ spine, distinct from MENA Black Gold|
|5|🇦🇷 Argentina|Tango|pull enemies together (no slow)|
|6|🇧🇷 Brazil|Redeemer|chance a leaked enemy costs no capital *(capstone)*|
|★|🇪🇨 Galápagos (Ecuador)|Forced Evolution|copies a random tower's profile *(special)*|

## 🟩 ASEAN — LOCKED
**Spine — Allure (armor break):** every tower shreds enemy armor (their own waves are armored swarms).

| Tier | Nation | Ability | Effect |
|--|--|--|--|
|1|🇰🇭 Cambodia|*spine only*|pure Allure (reduce enemy armor)|
|2|🇻🇳 Vietnam|North & South|sequential combo attack|
|3|🇵🇭 Philippines|Thousand Islands|atk speed up, range down|
|4|🇮🇩 Indonesia|Thousand Islands|atk speed up, range down (same name — archipelago twins)|
|5|🇲🇾 Malaysia|Petronas|**oil** aura — slow + amplify damage taken, can't attack (Petronas = the oil co.)|
|6|🇹🇭 Thailand|Beautiful Chaos|big range, random target *(capstone)*|
|★|🇸🇬 Singapore|Diplomacy|amplifies all allied buffs *(special — rehomes MENA's cut Cedars mechanic)*|

## ⬛ Africa — LOCKED
**"Soft spine" — The Wild:** no rigid shared mechanic; each tower is its own African icon.

| Tier | Nation | Ability | Effect |
|--|--|--|--|
|1|🇬🇭 Ghana|Juju|chance to hex an enemy into a critter|
|2|🇪🇹 Ethiopia|Caffeination|fast burst → crash (birthplace of coffee; Colombia/Cocaine = its extreme cousin)|
|3|🇨🇩 DR Congo|Cobalt|electrocute aura, speeds enemies up|
|4|🇰🇪 Kenya|Stampede|piercing charge + slow|
|5|🇳🇬 Nigeria|Afrobeat|fluctuating attack speed, low damage|
|6|🇿🇦 South Africa|Great White|% of enemy current HP *(capstone)*|
|★|🇸🇱 Sierra Leone|Blood Diamond|massive dmg + bounty, drains capital *(special)*|

## Open items
- **Recipes** — all specials use cross-region recipes; decided LAST.
- **New mechanics needed in code:** Wheat & Sky (gold-per-attack, E.Eur); per-kill *attack-speed* snowball (Croatia); spine-resets-only-on-kill (Russia/Mother Russia); **Propaganda** (Qatar — effective-tier override aura, up/down). Kaizen (per-kill *damage*) already exists → Japan.
- **Oil overlap RESOLVED:** MENA Black Gold = slow + amplify-all-damage; Venezuela Crude = **burn-amplifier only** (distinct, synergizes with S. America's Burn spine).
- **Future regions** banked: Central Europe (Germany, Netherlands…); North Africa Maghreb stays folded into MENA for now.
- **Colombia (S. America) → Cocaine** (stimulant/frenzy), NOT Cartel — Mexico owns Cartel now.
- **Slow-count watch:** remaining slows = Hungary (compound), Saudi (oil), Malaysia/Petronas (oil aura), Feel Good Man (double-edged). On the higher side — keep Africa light on slows.
- **Oil in 3 regions, differentiated:** Saudi/Black Gold (on-hit, slow + amplify-all), Venezuela/Crude (burn-amplify only, no slow), Malaysia/Petronas (aura, slow + amplify).
- ✅ **DESIGN COMPLETE** — 8 regions + 48 nations + 8 specials + all recipes locked. Next: **implement in code** (on user's go; no push until told).
- Stampede (Kenya) still carries a slow — last one on the watch-list; trim if slows feel heavy.

## The 8 specials + recipes — LOCKED (each cross-region, no base country reused)
| Special | Ability | Recipe (3 regions) |
|--|--|--|
|🇭🇷 Croatia|Checkered Past (perm atk-speed per kill)|🇮🇹 Italy + 🇭🇺 Hungary + 🇪🇬 Egypt|
|🇧🇪 Belgium|Bureaucracy (whole board, slow)|🇫🇷 France + 🇨🇩 DR Congo + 🇨🇿 Czechia|
|🇰🇵 North Korea|Juche (no auras; slow atomic missile)|🇰🇷 S. Korea + 🇨🇺 Cuba + 🇻🇳 Vietnam|
|🇶🇦 Qatar|Propaganda (sets allies to Qatar's tier)|🇸🇦 Saudi + 🇺🇸 USA + 🇪🇸 Spain|
|🇸🇻 El Salvador|CECOT (chance to imprison, no bounty)|🇲🇽 Mexico + 🇨🇴 Colombia + 🇵🇭 Philippines|
|🇪🇨 Galápagos|Forced Evolution (copies a random tower)|🇵🇪 Peru + 🇮🇩 Indonesia + 🇰🇪 Kenya|
|🇸🇬 Singapore|Diplomacy (amplifies all allied buffs)|🇨🇳 China + 🇲🇾 Malaysia + 🇬🇧 UK|
|🇸🇱 Sierra Leone|Blood Diamond (huge dmg+bounty, drains capital)|🇿🇦 S. Africa + 🇷🇺 Russia + 🇵🇦 Panama|
