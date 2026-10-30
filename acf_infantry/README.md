# ACF Infantry

<img width="256" height="256" alt="Acfinfantrysmall" src="https://github.com/user-attachments/assets/a35298e0-8669-470d-886c-590ca4325134" />

**ACF Infantry is a Garry's Mod infantry weapon and equipment pack built around ACF ballistics.** It brings small arms, guided missile launchers, throwable area effects, and support equipment into the same combat environment as ACF vehicles and props.

This customized version is based on [ACF-3-SWEPs](https://github.com/ACF-Team/ACF-3-SWEPs) and targets the [ACF-3 VSS fork](https://github.com/PERSON00331/ACF-3-VSS-FORK). It includes **31 spawnable items**: 16 firearms, 5 launchers, 4 throwable grenades, 2 deployable explosives, and 4 utility items.

## Recent Changes

### Storage reduction without removing equipment — October 30, 2026

Repacked selected large uncompressed AMR/XM25 textures into Source-compatible DXT5, keeping their existing dimensions, mip levels, normal-map flags, thumbnails and alpha content. This reduces disk/GPU texture storage without reducing resolution or changing UVs; standard block compression introduces small color/normal differences. Compression checks measure decoded pixel error; textures exceeding the conservative error threshold stay in their original format. Existing compressed textures, including the optimized AT4/syringe and appropriately sized C4/Claymore textures, are retained.

PNG files are losslessly recompressed only when smaller, with exact decoded RGBA pixels and dimensions preserved. Removed the superseded original syringe icon and unused duplicate `acf_logo.png`; the active transparent menu images, shared category logo and addon preview remain. All weapons, utilities, model/physics companions, animations, sounds, HUD and gameplay code are preserved. The incomplete prior ZIP was rebuilt from verified recovered entries and the intact previous pack before repacking; the complete output archive is checked for integrity.

### AT4, C4 and BO1 Claymore asset optimization — October 30, 2026

Reduced the AT4 diffuse and normal textures from 2048 × 2048 to their existing 1024 × 1024 mip levels, preserving DXT1 format, texture flags, thumbnails and all remaining mip blocks without recompression. C4 and the shared Insurgency hands retain their 1024-pixel textures; the BO1 Claymore retains its 512-pixel textures. These were already appropriately sized. AT4 close-up texture detail is modestly reduced.

Removed the unused `weapon_w_at4_dm` material and its diffuse/normal maps: both compiled AT4 models actually reference `weapon_at4_dm`. Removed the superseded donor AT4/C4 PNGs and BO1 Claymore VMT/VTF menu icon, and removed those entries from client-download manifests. The current transparent menu icons remain unchanged. All model/physics companions, animation sequences, active materials, hand assets, handling/fire sounds and gameplay files are retained. Asset/format checks passed; appearance still requires in-game confirmation.

### C4 attachment to parented props — October 30, 2026

C4 now checks its swept travel path for parented prop/ACF entities as well as normal solid surfaces, covering child props without independent physics collision callbacks. A short release-path check also supports throwing directly against a nearby parented prop. Parent candidates are shared across charges once per physics tick, with bounds checks before oriented-box intersection; normal solid traces still block attachment through walls. Non-solid parented props use their model bounding box, so hollow or concave models may attach at the box surface rather than an exact mesh triangle.

The charge attaches directly to the struck child, using contact position and angle captured in that child's local coordinates before deferred parenting. It follows movement and rotation through the existing parent chain. World attachment remains unparented; characters, sky and invalid contacts are rejected, and duplicate attachment is blocked. If the target disappears before attachment, the charge remains free. Existing C4 throw settings, 120 mm fragment target, blast, arming, 15-charge limit, recovery and HUD remain unchanged. Claymore placement is unchanged. Parented moving contraptions still need in-game validation.

### Native C4 and Claymore fragment penetration — October 30, 2026

Both explosives now calibrate their native AP fragments to **120 mm RHA penetration at launch**, increased from 40 mm. This changes the shared server-side penetration target used to solve fragment velocity through the installed ACF AP penetration function; it is not a display-only number. Each retains 60 fragments: radial for C4 and forward-directed for Claymore. Impact penetration still follows native velocity loss, armor slope and other ACF rules; native HE blast/casing damage is separate and does not have one fixed penetration value. Blast reach, active limits, C4 throw calibration, models, animations, HUD and menu icons are unchanged.

### Claymore blast reach and 40 mm fragments — October 29, 2026

The Claymore now solves its native ACF filler amount so the actual blast radius reaches **110% of its 180-unit trigger range (198 units)**, avoiding the previous approximately 126-unit blast cutoff before targets at the trigger boundary. The minimum configured filler remains 0.0625 kg; the effective value is calculated against the installed fork's radius function (approximately 0.245 kg with current VSS defaults). The visual explosion uses the same effective filler and radius. Native blast damage still falls off with distance and respects cover/armor.

Both C4 and Claymore now emit **60 native AP fragments calibrated to 40 mm RHA penetration at launch**, using a 12 mm AP round and the installed fork's penetration function to calculate launch speed. C4 fragments spread uniformly in all directions; Claymore retains its forward 60° × 20° pattern. Penetration at impact remains subject to native velocity loss, angle and armor calculations. The native blast/casing damage remains separate and has no single fixed penetration number. A fragment-conversion failure is reported without cancelling the blast. The removed Claymore trigger-sound reference is replaced by a stock cue. Active limits (15 C4 / 8 Claymores), arming, HUD and controls are unchanged.

### Deployable limits, explosive power and HUD — October 29, 2026

Active limits are now **15 C4 charges and 8 claymores per player**, tracked separately by type. Both the initial placement check and the release-time check enforce these limits. The deployed-count HUD uses the same limit as placement, displaying `count / 15` for C4 and `count / 8` for Claymore; ready ammunition, reserves and controls remain visible.

Both native ACF explosive filler and casing inputs increase by **25%**: C4 uses **0.625 kg filler / 0.125 kg casing**, and Claymore uses **0.0625 kg filler / 0.025 kg casing**. Claymore forward AP fragments also increase **48 → 60** (+25%); their speed, caliber and penetration configuration are unchanged. ACF calculates actual blast damage and radius, so these input increases do not promise exactly 25% more damage or radius at every distance. Arming times, detection range/cone, recovery and other behavior remain unchanged.

### Black Ops 1 Claymore replacement — October 29, 2026

The ACF Claymore now uses the **Black Ops 1** model from the supplied **Black Ops Claymore (Sandbox)** archive, including its first-person model, normal player hands, pullout/placement animation sequences, held/deployed world model, menu image and handling/plant sounds. The held model uses the donor's hand placement. Only BO1 presentation assets are included; BO2 assets, donor entities, laser effects, settings menus and donor damage code are excluded.

Native ACF blast/fragmentation, 1.5-second arming, 180-unit / 80-degree detection cone, 0.25-second trigger delay, owner exclusion, four-mine limit, recovery, 100 reserve rounds, controls and HUD are unchanged. The BO1 model faces local -Right, matching the existing placement and forward-fragment direction. Remaining CoD Remastered Claymore/arm assets have been removed. AT4, C4, syringe and unrelated equipment are unchanged. Model placement and animation still require in-game confirmation.

### Insurgency AT4 and C4 replacement — October 29, 2026

- **ACF AT4** replaces the Javelin's name, first/third-person models, menu image, draw/fire animations and CLU view. Right click now uses the Insurgency AT4 iron sights, with the existing mild weapon zoom and suit-zoom support. The ammo/status HUD remains visible. The model and its matching arms are hidden during the existing four-second reload.
- This is a presentation change: the AT4 retains the existing **BGM-71E HEAT missile, Wire SACLOS guidance, 20/18 cm round lengths, 90° liner, zero extra standoff, three-second equip arming, movement penalties, grounded-only firing, safety and 100-round reserve**. It is not a simulation of a real unguided, disposable AT4. Keep holding aim after firing to guide it. The legacy class `weapon_acf_panzerschreck` remains compatible.
- **ACF C4** now uses the Insurgency charge/detonator viewmodel, charge world/deployed model, throw and trigger animations, handling sounds and menu image. The deployed object is the explosive charge. Its native ACF damage, 0.5 kg filler, one-second arming, sticky placement, four-charge limit, reserve ammunition, recovery and remote controls are retained.
- Matching Insurgency arms are bundled and reused by these two weapons, with cleanup on holstering/removal. Only the needed presentation assets are included; the donor weapon/entity code, other explosives and large explosion-sound collections are excluded. No separate Insurgency addon or TFA base is needed.
- Replaced CoD Javelin/C4-only files have been removed. The existing CoD Claymore and its shared arm assets remain. The syringe's previous texture optimization and all unrelated equipment remain unchanged.

### Earlier updates (historical)

The entries below describe earlier builds; the AT4/C4 replacement above supersedes the former Javelin and CoD C4 presentation details.

### Syringe texture optimization — October 29, 2026

The Alyx health stim's diffuse, normal and liquid textures now use their original 1024 × 1024 mip levels instead of 2048 × 2048, saving 12 MiB extracted. Their DXT5 format, alpha channels, flags and remaining mip data are preserved without recompression. View/world models, player hands, animation sequences, Q-menu image, sounds, healing and protection are unchanged. Close-up texture detail is reduced; visual appearance still needs confirmation in Garry's Mod.

### Gradual, randomized grenade fire — October 28, 2026

Fire now ignites near the grenade first and spreads outward over approximately 2–2.3 seconds on suitable ground. Patch centers have small random offsets while retaining overlapping coverage; each patch starts dealing damage only once it ignites. Flame timing, size, lifetime, color and motion vary independently between patches. The 15-second duration still starts at detonation, with unchanged 120-unit patch radius, 250-unit maximum reach, character damage, and wall/water checks. Overlapping patches still do not stack damage.

### Automatic XM25 — October 28, 2026

The XM25 now fires automatically while the trigger is held. Its existing 0.3-second shot interval (200 rounds/minute), 12-round magazine, reserve ammunition, accuracy, recoil, and 25 mm HE projectile settings are unchanged.

### Alyx syringe presentation — October 28, 2026

- The health stim now uses the bundled **HL:A Gear Medishot** viewmodel (`models/weapons/c_medishot.mdl`) and world model (`models/weapons/w_medishot.mdl`), with normal player hands and the supplied `draw`, `idle`, and `inject` sequences. The former floating health-vial prop and lift animation are removed.
- Named animation playback uses the pack's existing owner-client animation helper, without requiring TFA or a separate HL:A Gear installation. The donor only has one injection sequence, so both self-use and healing another target reuse it, fitted to the existing action delays.
- Healing remains **50 HP over 10 seconds**, capped at 100 (or the target's lower max health), with **15% damage reduction for 20 seconds**. Charges, repeat-use timer refreshes, other-target range checks, and the HUD remain unchanged. The original stock health-kit use sound is retained; the archive did not contain the donor Lua's referenced `items/medshot4.wav`.

The Q-menu folder previously named **Grenades** is now **Throwables and Deployables**, containing the four throwable grenades, C4, and claymore.

### Javelin presentation and deployable explosives — October 28, 2026

- The former Panzerschreck/TOW entry is now **ACF Javelin**, with the supplied CoD Remastered Javelin model, named draw/fire/reload/aim sequences, 30-degree aiming FOV, and CLU scope graphics. Its ACF **BGM-71E HEAT payload and Wire SACLOS guidance remain unchanged**: this is a presentation replacement, not a new fire-and-forget/top-attack missile. Continue holding aim after launch to guide it.
- Added **ACF C4** and **ACF Claymore** under the existing **Throwables and Deployables** folder, with bundled models, materials, sounds, named animations, and native VSS ACF blast/fragmentation damage. No TFA base is required. See [Deployable Explosives](#deployable-explosives) for controls and balance settings.
- Existing launcher ammunition, reload/arming times, movement penalties, grounded-firing restrictions, safety, and the ACF HUD are preserved. The replacement keeps `weapon_acf_panzerschreck` for compatibility.

### Earlier balance and grenade updates

Compared with [WiseOL/ACF-Infantry](https://github.com/WiseOL/ACF-Infantry) at commit [`c42d059`](https://github.com/WiseOL/ACF-Infantry/commit/c42d059f2967145f18b708c3bc036db9d85b24bb), checked October 26, 2026. This comparison describes the downloadable pack; it does not mean these changes have been pushed to GitHub.

| Area | GitHub baseline | Updated pack |
| --- | --- | --- |
| Bazooka, Javelin (formerly TOW), Stinger | No dedicated grounded-firing guard | Firing is blocked while airborne or pressing jump. SMAW and XM25 remain exempt. |
| SMAW ammunition | 60 mm APCR; 9 cm projectile; 39 cm propellant | 40 mm APCR; 6 cm projectile; 26 cm propellant, using the maximum propellant and minimum projectile lengths permitted for this cannon caliber. |
| SMAW movement | No heavy-weapon movement reduction | Walking, slow-walking, and sprinting are reduced by 15% while equipped, using the existing heavy-weapon movement handler. M1919 and M249 retain their existing penalties. |
| Suit Armor | 200 armor cap | 150 armor cap, including the HUD capacity. Still +25 per successful use and eight charges per item; six uses reach the cap from zero. |
| Shotgun pellet pattern | 1.25-degree pellet cone half-angle | 0.9375-degree pellet cone half-angle: 25% tighter. Still 24 pellets, with unchanged shot-center accuracy, handling, recoil, speed, and per-pellet damage settings. |
| Smoke, nerve gas, Venomous Agent X audio | Unmanaged ambient steam loop | Finite CS:S smoke-grenade burst replaces the loop. Fire sound cleanup is also performed client-side on removal and expiry, in addition to server-side cleanup. |
| Grenade player contact and fuse | Player collision; fuse checked in entity Think | Player–grenade physical collision is disabled. An independent server fuse timer backs up Think, with duplicate-detonation protection. Fire-placement traces ignore characters while retaining wall, ground, and prop checks. |

The newer Stinger model/seeker, health-vial stim, and their existing UI are already present in the comparison commit; they are not new differences in this update. Beyond the additions and changes listed above, other weapon definitions and utilities, missile payloads, and throwable-grenade damage/radius/duration/fuse settings remain unchanged. The XM25 Lua file has only an extra trailing blank line; the armor material differs only in line endings.

File/package checks and targeted Lua checks were completed during these updates. The grenade sound and standing-over-grenade fixes still need confirmation in Garry's Mod.

## Features

- ACF projectile interaction with vehicles, armor, and props.
- Rifles, pistols, machine guns, a shotgun, and a rebar crossbow.
- Wire-guided anti-tank missiles and an infrared anti-aircraft launcher.
- Smoke, fire, nerve gas, and Venomous Agent X grenades, plus remote C4 and directional claymores.
- Suit armor, healing equipment, EPO, and persistent thermal goggles.
- A compact vertical HUD anchored to the bottom-right corner.
- Weapon safety toggles, magazine/reserve displays, and launcher status information.
- Organized **Weapons**, **Launchers**, **Throwables and Deployables**, and **Utility** folders beneath **ACF Infantry** in the Q menu's Weapons tab.

## Requirements

| Dependency | Used for |
| --- | --- |
| [ACF-3 VSS fork](https://github.com/PERSON00331/ACF-3-VSS-FORK), with its required dependencies | The ACF ammunition, damage, ballistics, and native missile APIs targeted by this version |
| Matching ACF missile support | AT-3, BGM-71E, and FIM-92 missile classes, guidance, motors, and fuzes |
| Counter-Strike: Source content | CSS firearm/grenade models, animations, and the EPO defuser model |
| [Wiremod](https://github.com/wiremod/wire) with FLIR support | Thermal goggles and camera-controller thermal integration |
| Bundled FIM-92 Stinger assets, credited below | Dedicated Stinger view/world models, materials, deploy sound, and seeker tone |

The health stim uses bundled Medishot models and textures from the user-supplied **[TFA] HL:A Gear** archive. Its animation playback uses native Garry's Mod calls, so it needs neither TFA nor the separate donor addon installed. The previous Rust syringe assets and separate experimental Medical Shot compile kit are not part of this release.

Wiremod's FLIR support is required for thermal vision. The remainder of the pack still requires ACF. Compatibility with other ACF forks or older APIs should be checked rather than assumed.

## Installation

1. Install the required ACF version and its dependencies on the server.
2. Install the matching missile support and Wiremod.
3. Mount Counter-Strike: Source content where required on the server and clients.
4. Extract this addon into `garrysmod/addons/acf_infantry/`.
5. Confirm that `addon.json`, `lua/`, `materials/`, and `models/` are directly inside that folder.
6. Remove older duplicate installations of this pack, then restart the server and reconnect.
7. Open **Q menu → Weapons → ACF Infantry** and choose a subfolder.

Do not leave the addon as an unextracted ZIP. Avoid an extra nested directory such as `addons/acf_infantry/acf_infantry/lua/`.

## Controls

| Item | Control | Action |
| --- | --- | --- |
| Firearms | Left click | Fire |
| Firearms | Right click | Aim or use the weapon's scope |
| Supported select-fire firearms | Use + right click, normally **E + RMB** | Switch automatic/semi-automatic mode |
| Firearms and launchers | **R** | Reload |
| Firearms and launchers | **B** | Toggle safety |
| Guided missile launchers | Hold right click, then left click | Aim and launch; Stinger requires a two-second target lock |
| Bazooka / AT4 | Continue holding aim with the launcher equipped | Guide the missile toward the current aiming point |
| Grenades | Hold left click, then release | Pull the pin and throw |
| Grenades | Right click | Pull the pin and automatically drop just ahead of your feet |
| Grenades | **R** | Ready another grenade from reserve |
| Suit armor | Left click | Apply 25 armor |
| Health stim | Left click | Inject yourself |
| Health stim | Right click | Apply the stim to a nearby living player or NPC; keep aiming until application finishes |
| EPO | Left click | Use EPO |
| Thermal goggles | Left click while equipped, or **N** while carried | Toggle thermal vision |

Safety applies to guns and launchers, not grenades or utility items. A fresh trigger press is required after changing safety. Native suit zoom remains available.

## Firearms

These are **configured ACF calibers and round types**, not a claim that every weapon uses its real-world ammunition. The anti-material rifle and crossbow intentionally use custom APCR rounds.

| Weapon | Configured caliber | Round type | Loaded capacity |
| --- | --- | --- | --- |
| ACF AK47 | 7.62 mm | AP | 30 |
| ACF Anti-Material Rifle | 27 mm | APCR | 1 |
| ACF AUG | 5.56 mm | AP | 30 |
| ACF Desert Eagle | 12.7 mm | AP | 7 |
| ACF Glock 18 | 9 mm | AP | 24 |
| ACF Garand | 7.62 mm | AP | 8 |
| ACF Kar98k (Scoped) | 7.92 mm | AP | 5 |
| ACF Lapua | 8.61 mm | AP | 5 |
| ACF M1919 | 7.8 mm | AP | 250 |
| ACF M249 | 5.56 mm | AP | 100 |
| ACF M4A1 | 5.56 mm | AP | 30 |
| ACF MP5 | 9 mm | AP | 30 |
| ACF Rebar Crossbow | 23 mm | APCR | 1 |
| ACF Revolver | 9.06 mm | AP | 6 |
| ACF SG550 Commando | 5.56 mm | AP | 30 |
| ACF Shotgun | 2.5 mm projectile setting | AP | 7 |

The shotgun's listed caliber is its configured projectile value, not its nominal shell gauge. Each shot fires 24 pellets. The pellet cone half-angle is 0.9375 degrees (25% narrower than the previous 1.25 degrees). Shot-center accuracy, handling, recoil, pellet count, projectile speed, and per-pellet damage settings are unchanged; it remains buckshot rather than a single slug.

### Ammunition and handling

- Guns and launchers are configured to start loaded, with **100 rounds in reserve**. Weapons sharing a Garry's Mod ammo pool also share that reserve; existing inventory and ammo grants can affect the displayed total.
- The pack's balance adjustments reduce base spread and handling inaccuracy, improve aimed accuracy, and reduce recoil compared with the original configuration.
- The **M1919, M249, and SMAW reduce walking, slow-walking, and sprint movement by 15% while equipped**.
- The Bazooka, AT4, and Stinger can fire only while grounded. Jump + fire inputs are blocked, as is firing while falling or otherwise airborne.
- The SMAW and XM25 are exempt from the grounded-firing restriction; the SMAW can fire without aiming down sights.
- Select-fire behavior depends on each weapon's configuration; not every firearm has multiple firing modes.

### Custom APCR ammunition

These weapons use native ACF ammunition conversion rather than a manually assigned penetration number.

| Weapon | Native weapon class | Caliber | Projectile length | Propellant length |
| --- | --- | --- | --- | --- |
| Anti-Material Rifle | Autocannon | 27 mm | 4.05 cm | 17.55 cm |
| Rebar Crossbow | Cannon | 23 mm | 3.45 cm | 14.95 cm |
| SMAW | Cannon | 40 mm | 6.00 cm | 26.00 cm |

## Launchers

| Weapon | Projectile | Guidance | Loaded capacity | Reload |
| --- | --- | --- | --- | --- |
| ACF Bazooka | AT-3 HEAT missile | Wire / SACLOS | 1 | 4 seconds |
| ACF AT4 | BGM-71E HEAT missile | Wire / SACLOS | 1 | 4 seconds |
| ACF Stinger | FIM-92 HE missile | Infrared | 1 | 2 seconds |
| ACF SMAW | 40 mm APCR cannon round | Unguided ballistic projectile | 1 | Weapon-base reload behavior |
| ACF XM25 | 25 mm HE projectile | Unguided ballistic projectile | 12 | Weapon-base reload behavior |

The SMAW is configured as a cannon-round launcher. It does not fire a guided missile.

### Missile payload settings

Projectile and propellant lengths below are ammunition-conversion inputs in centimeters. They are not a direct substitute for missile motor or flight configuration.

| Launcher | Projectile length | Propellant length | HEAT liner angle | Extra standoff ratio | Filler ratio |
| --- | --- | --- | --- | --- | --- |
| Bazooka / AT-3 | 16.00 cm | 26.00 cm | 90° | 0.00 | Native HEAT conversion |
| AT4 / BGM-71E | 20.00 cm | 18.00 cm | 90° | 0.00 | Native HEAT conversion |
| Stinger / FIM-92 | 60.00 cm | 80.00 cm | Not applicable | Not applicable | 0.48 |

- **Bazooka:** three-second arming period after equipping. Sprinting is blocked during arming, walking is reduced by 25%, and sprint speed is reduced by 30% once armed.
- **AT4 (TOW payload):** three-second arming period after equipping. Sprinting is blocked during arming, walking is reduced by 50%, and sprint speed is reduced by 50% once armed.
- **Stinger:** no additional equip-arming period or launcher movement penalty. The native missile fuze still has its own arming behavior. Infrared guidance operates autonomously after launch, with a radio proximity fuze configured for approximately 3 meters. The dedicated FIM-92 model uses upstream sight/idle offsets, eased aiming, reduced aimed sway, and its own sprint pose. It requires a two-second lock while aiming at an eligible ACF target; a seeker tone and blue/red target marker show acquisition and lock. Losing sight, lowering the weapon, reloading, enabling safety, or changing targets clears/restarts acquisition. The locked target is passed to native infrared guidance after launch. There is no added movement penalty.
- Wire-guided missiles follow the player's current aiming point while the owner is alive, holding aim, and keeping that launcher active. Native wire range and wire-break behavior still apply.

For compatibility with existing saves or bindings, the AT4 replacement retains the legacy entity class `weapon_acf_panzerschreck`. The SMAW retains `weapon_acf3r_smaw`, and the XM25 retains `weapon_acf_grenadelauncher`.

The Insurgency AT4 model and iron sights replace the former Javelin presentation only. Its native missile remains BGM-71E HEAT with the listed 20/18 cm payload settings and Wire SACLOS guidance. This is a custom guided launcher rather than a real-world disposable AT4. The former CLU overlay is removed. Named sequence playback and matching arm rendering are implemented independently of the donor weapon code.

## Throwables and Deployables

### Grenades

All grenade types have separate ammunition pools and start with **one ready grenade plus 100 in reserve**. The shared limit permits up to six active grenade/cloud/fire entities per player. Right-click dropping uses the same ammunition and fuse as throwing.

| Grenade | Active duration | Character damage | Area | Fuse |
| --- | --- | --- | --- | --- |
| ACF Smoke Grenade | 30 seconds | None | Expanding visual smoke; no fixed damage radius | 2 seconds |
| ACF Fire Grenade | 15 seconds | 15 HP/second | Continuous coverage on suitable open ground, capped at 250 units from the grenade | 3 seconds |
| ACF Nerve Gas Grenade | 15 seconds | 3 HP/second | 250-unit radius | 3 seconds |
| ACF Venomous Agent X | 15 seconds | 8 HP/second | 250-unit radius | 3 seconds |

Damage rates are configured values before normal damage hooks or other protection. Damage is processed in quarter-second ticks; server timing can affect the realized rate.

### Throwing and dropping

| Grenade | Forward throw impulse | Upward throw impulse |
| --- | --- | --- |
| Smoke | 650 units/second | 90 units/second |
| Fire, nerve gas, Venomous Agent X | 1,000 units/second | 100 units/second |

Throws also inherit player velocity. Right-click drops inherit player velocity without the forward/upward throwing impulse. The fuse begins when the grenade entity spawns, after the pin-pull/release animation; holding the grenade does not cook the fuse.

### Smoke

The smoke grenade uses native VSS smoke-round conversion with a **20 mm caliber**, **17.49 cm projectile**, **0.01 cm propellant**, **1.00 filler ratio**, and **0.07 native SmokeWPRatio input**.

Its private client effect uses ACF smoke materials and dispersion, with both cloud components set to a 30-second lifetime. It does not create ignition, native WP damage clouds, or explosion damage. Smoke is visual cover; it does not explicitly block NPC targeting or infrared guidance.

### Fire

Fire spreads outward over approximately **2–2.3 seconds**, using overlapping **120-unit patches** with small randomized position offsets to cover a continuous area on unobstructed ground, with a hard outer reach of **250 units**. Walls, unsuitable terrain, and water can interrupt that coverage. Overlapping patches from the same grenade do not multiply damage to one target.

Players, NPCs, and NextBots use the configured character damage rate. ACF props receive separate low-penetration thermal damage through ACF's armor calculations; they do not simply lose 15 ACF HP per second.

### Nerve gas and Venomous Agent X

Both clouds damage characters through suit armor while retaining normal damage hooks. Armor bypass is handled separately from toxin damage flags, so these grenades do not trigger the HEV suit's neurotoxin-detected or antidote-administered announcements. The addon does not administer antidotes. Walls block exposure, and submerged targets are excluded. Underwater detonation does not create a gas cloud.

- **Nerve gas:** reverses forward/backward and left/right movement while exposed, with approximately 0.4 seconds of lingering reversal after leaving. Smoke color: **RGB 209, 33, 33**.
- **Venomous Agent X:** does not reverse movement. Smoke color: **RGB 216, 125, 73**.
- Both use the same visual smoke payload inputs: **20 mm**, **11.13 cm projectile**, **0.05 cm propellant**, **1.00 filler ratio**, and **0.01 native SmokeWPRatio input**.
- Gas damage does not damage ACF props. Separate grenade clouds can apply overlapping damage.

The native VSS field is named `SmokeWPRatio`; its value is passed directly to ACF conversion. These visual payload settings do not change the explicitly configured gas damage radius or duration, and the gas visuals do not spawn native WP damage clouds.

## Deployable Explosives

Both items appear in **ACF Infantry → Throwables and Deployables**, use separate ammo pools, and start with **one ready device plus 100 reserve**. The HUD shows ready/reserve ammo, deployed count, and controls. Each player may have **15 active C4 charges and 8 active claymores**. Their runtime code does not use the donor's flat `util.BlastDamage` or require TFA.

| Item | Primary | Secondary | Arming | Native ACF payload |
| --- | --- | --- | --- | --- |
| ACF C4 | Throw a short-range sticky charge | Detonate your armed C4 charges | 1 second | 0.625 kg TNT-equivalent filler; 0.125 kg casing, plus 60 radial AP fragments at 120 mm launch penetration |
| ACF Claymore | Plant on clear, reasonably level ground ahead, facing away from you | No secondary action | 1.5 seconds | Native filler calibrated for 198-unit blast reach; 0.025 kg casing, plus 60 forward AP fragments at 120 mm launch penetration |

- **C4:** thrown at 800 units/s forward plus 100 units/s upward and player velocity, with per-device gravity calibrated for approximately 600 units on a stationary level throw. It sticks to world/prop surfaces after contact. Detonation uses the current owner's C4 only; unarmed charges are skipped. Detonator animation is cosmetic and does not add a separate blast delay.
- **Claymore:** detects other living players, NPCs, NextBots, and moving vehicles/ACF entities within **180 units** and an **80-degree forward cone**, with a line-of-sight check. It ignores its placing player; there is no team filter. Triggering starts a **0.25-second delay**. Its AP fragments use native ACF flight, with launch speed calibrated for **120 mm RHA penetration**, with a **60-degree horizontal / 20-degree vertical** forward spread. The small blast is omnidirectional; the additional AP fragments are directional. Lasers indicate the forward sector but are cosmetic, not exact tripwire collision beams.
- Press **E** on your own device within **96 units** to recover one reserve round, provided that ammo pool is below 100 and the device has not triggered. Press **R** to ready another device; a new device is also readied automatically after placement when ammunition is available.
- Devices have 10 engine health; shooting them out before arming removes them, while destroying an armed device requests detonation. Native ACF prop damage can also destroy devices through its own handling.
- Devices disappear after **180 seconds**, on owner death/spawn/disconnect, or via the player's **ACF Infantry Explosives** cleanup entry. Pending callbacks validate the entity before acting.
- Blast radius, damage, fragmentation penetration, armor response, and damage permissions depend on the installed VSS ACF code and server hooks. These are game balance inputs, not fixed damage numbers. There is no duplicate generic blast-damage pass.

## Utility equipment

### ACF Suit Armor

- Adds **25 suit armor per successful use**, up to **150 armor**.
- Six successful applications reach 150 armor from zero. Each item retains eight uses; remaining uses can replenish armor after taking damage.
- Using it at the cap does not spend a charge.
- Displays an upright armor item without first-person hands or arms, with the plate facing the player and offset from the crosshair.
- The plate rests closer to the player and moves upward and toward the face during a successful application, then returns to its resting position.
- Uses the bundled armor plate at `models/acf_infantry/armor_plate.mdl`, including its materials and application sound. No separate battery-replacement addon is required, and standard HEV batteries are not replaced.

### ACF Health Stim

- Heals **50 HP over 10 seconds**, capped at **100 HP** or the target's lower maximum health.
- Provides **15% damage reduction for 20 seconds**, independently of the healing timer.
- Can be used at full health for protection without raising health above the cap.
- Left click treats the user; right click treats a nearby living player or NPC.
- Healing another target requires maintaining aim/contact until the application delay finishes. Breaking contact cancels without consuming the stim.
- Each pickup supplies one medical charge. Additional pickups add charges to the same ammunition pool (up to 100). Each successful application consumes one charge; another use can begin once the application delay finishes.
- Reusing a stim on an affected target restarts healing at 50 HP over the next 10 seconds and refreshes 15% damage reduction to 20 seconds. Old healing is replaced, not added, and damage reduction does not stack. The 100 HP cap remains.
- Presentation uses `models/weapons/c_medishot.mdl` and `models/weapons/w_medishot.mdl` with player hands. Named `draw`, `idle`, and `inject` animations replace the floating-prop renderer. It retains the stock health-kit use sound.
- Application timing remains 3.6 seconds for self-use and 2.84 seconds for another target. The same supplied injection sequence plays over 3.4 or 2.64 seconds respectively, with a 0.2-second completion buffer. There is no separate outstretched-arm animation in the donor model. Self-healing begins on accepted use; healing another target begins when the contact/application delay completes.
- Uses no activation chat messages. Player effects are cleared on death, spawn, or disconnect.

### ACF Erythropoietin (EPO)

A single-use movement boost followed by a temporary crash:

| Phase | Duration | Sprint speed | Jump change |
| --- | --- | --- | --- |
| Active | 30 seconds | +20% | +20% jump height |
| Crash | 30 seconds | −30% | −30% jump power |

The boost adjusts jump velocity by the square root of 1.2 to target a 20% height increase. The crash directly reduces jump power; it is not a 30% height reduction. EPO cannot be reused during either phase. The system attempts to preserve independent movement changes made by other addons when restoring values.

### ACF Thermal Goggles

- Uses Wiremod FLIR thermal rendering.
- Toggle with **N** while the goggles are in the player's inventory, or left click while equipped.
- Remains enabled when holstered, allowing the player to use other weapons.
- Combines goggles' thermal demand with Wire camera-controller FLIR demand.
- Resets on death or when the goggles are no longer carried.
- Has no visible radio world model and no first-person hands or arms.

This is an inventory utility and FLIR bridge, not a physical pair of goggles attached to the player model.

## HUD

The HUD forms a narrow vertical stack at the **bottom-right** of the screen. It uses the ACF overlay palette with translucent panels and blue/red accents.

Depending on the equipped item, it shows:

- Loaded ammunition and a vertical fill bar.
- Reserve ammunition, ammunition type, and fire mode.
- Safety state and launcher arming/reload/guidance information.
- Stacked spare-magazine or spare-round indicators.
- Grenade controls and fuse information.
- Armor or utility information.
- Persistent EPO, stim-protection, and thermal indicators beneath the active item.

Spare-magazine indicators are calculated from loose reserve ammunition and magazine capacity; they are not separately stored magazine objects. The HUD preserves weapon scope rendering and supports the SMAW's legacy class name.

## ACF damage and penetration

**Configured values and calculated results are different.** Caliber, round type, projectile length, propellant length, filler ratio, and guidance settings are configuration inputs. ACF uses those inputs and its own rules to calculate round mass, velocity, explosive filler, penetration, and damage behavior.

Actual results can vary with:

- The installed ACF fork and ammunition implementation.
- Server settings and damage hooks.
- Impact speed, distance, angle, armor thickness/material, and standoff.
- Missile motor, guidance, target, fuze, and arming behavior.

Garry's Mod ammo-pool names such as `SMG1` or `AR2` control inventory sharing; they do not define an ACF round's penetration or damage. The name/model of a SWEP also does not necessarily identify its current ballistic payload.

## Server diagnostics

Administrators or the server console can enable temporary missile diagnostics:

```text
acf_infantry_missile_diagnostics
```

The trace lasts approximately 120 seconds and reports native conversion, launch, guidance, detonation, and HE damage information to the console. It does not change damage results.

The `acf_infantry_stim_diagnostics` command reports the equipped model and use timing. The Alyx viewmodel has `draw`, `idle`, and `inject`; it does not have sequences named `deploy` or `inject_other`. The stim maps its internal deploy/other-use actions to the supplied names explicitly. Missing names in the diagnostic output do not alone indicate a playback failure.

The safety toggle is also available as a client console command:

```text
acf_infantry_toggle_safety
```

## Troubleshooting

| Problem | Check |
| --- | --- |
| Missing/error models or missing sounds | CSS content, the bundled Stinger assets, matching server/client content, and model-replacement addons |
| Missiles fail to launch, guide, or damage ACF | Correct VSS/ACF missile APIs, required native missile classes, a clean restart, and the missile diagnostic command |
| Thermal vision unavailable | Wiremod FLIR support and possession of the goggles |
| Old weapons, old HUD, or duplicate entries | Remove older copies of this addon and reconnect after a server restart |
| Missing Q-menu folders | Updated addon files, a current Garry's Mod build, and a rebuilt/reopened spawn menu |
| Missing armor plate model or texture | Ensure the bundled `models/acf_infantry/armor_plate.*` and `materials/models/items/armorplate/` files reached the client, then restart and reconnect |
| Healing another player cancels | Maintain aim/contact and ensure the target is alive |

When reporting a bug, include the weapon/item name, server ACF version or commit, Lua error text, and steps to reproduce it. For missile problems, include diagnostic console output. Animation, model placement, and multiplayer prediction changes should be verified in Garry's Mod; standalone Lua checks do not replace in-game testing.

## Credits and license

- **ACF-3-SWEPs contributors / LiddulBOFH** — original infantry weapon addon and foundation.
- **ACF Team and VSS fork contributors** — ACF framework, ballistics, damage, ammunition, and missile systems.
- **Wiremod contributors** — FLIR and camera-controller functionality.
- **Rocks** — [Vanilla-Styled FIM-92 Stinger](https://steamcommunity.com/sharedfiles/filedetails/?id=3807683332), the model/deploy assets incorporated through upstream ACF-3-SWEPs.
- **FrazierWing** — [SideWinderGrowl.wav](https://freesound.org/people/FrazierWing/sounds/569666/), CC0, used for the Stinger seeker tone.
- Stinger presentation and seeker logic adapted from upstream ACF-3-SWEPs commit [`b52ea0c854c837d2d241c8ef0e1113e106f4f2eb`](https://github.com/ACF-Team/ACF-3-SWEPs/commit/b52ea0c854c837d2d241c8ef0e1113e106f4f2eb); the pack retains its VSS missile adapter and configured payload, damage path, 2-second reload, 100 reserve rounds, and movement behavior.
- **Valve** — Source and Counter-Strike: Source game assets used through mounted content.
- **Armor Plate Replacement** — armor model, materials, and sound from [the Workshop addon](https://steamcommunity.com/sharedfiles/filedetails/?id=2622292371), as credited in the GitHub README.

**Code license: MIT**, matching [ACF-3](https://github.com/ACF-Team/ACF-3). The original SWEP code already includes the MIT license in [LICENSE.md](LICENSE.md). Keep that notice and any applicable third-party notices. The code license does not grant ownership of Valve, Workshop, or other third-party assets. Bundled third-party assets retain their original authorship; other game assets are supplied through mounted dependencies. Respect the applicable asset licenses and redistribution terms.

### Additional bundled presentation assets

The earlier Claymore presentation assets and shared arms (now removed) were extracted from the user-supplied **[TFA] CoD Remastered Explosives Pack** archive. The donor weapon files credit **Krazy** and identify the Call of Duty: Modern Warfare Remastered source. These game/Workshop assets retain their original authorship and applicable terms. This integration supplies separate ACF runtime code and does not bundle or depend on the donor's TFA weapon bases, missile entities, or generic explosion damage code.

The Medishot model and materials come from the user-supplied **[TFA] HL:A Gear** archive; its healthshot weapon credits **Mazima Gofo**. Half-Life: Alyx game assets retain Valve's authorship and applicable terms. The donor Lua healing code is not included or used, and its TFA base is not a dependency.

The AT4 and C4 presentation models, textures, menu images, matching Insurgency arms and selected handling/fire sounds come from the user-supplied **Insurgency Explosives Pack** archive. Its metadata gives the placeholder author name “Author Name”; it does not identify a verifiable Workshop creator. Insurgency game assets retain their original authorship and applicable terms (New World Interactive). Only selected assets are bundled, with separate ACF integration code; no donor weapon damage/entity code or external weapon base is used.

The current Claymore's BO1 presentation assets are from the user-supplied **Black Ops Claymore (Sandbox)** addon. Its weapon source credits **Hoff**. Black Ops game assets retain their original authorship and applicable terms (Treyarch/Activision).
