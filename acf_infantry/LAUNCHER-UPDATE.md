# ACF Infantry launcher settings

| Weapon | Projectile input (cm) | Propellant input (cm) | Ammo | Guidance | Other inputs |
|---|---:|---:|---|---|---|
| ACF Stinger | 60.0 | 80.0 | HE | Infrared | Filler ratio 0.48 |
| ACF SMAW | 9.0 | 39.0 | 60 mm cannon APCR | Unguided | No explosive filler |
| ACF Bazooka | 16.0 | 26.00 | AT-3 HEAT | Wire (SACLOS) | Liner angle 90.0; extra standoff ratio 0.00 |
| ACF TOW Launcher | 20.0 | 18.00 | BGM-71E HEAT | Wire (SACLOS) | Liner angle 90.0; extra standoff ratio 0.00 |

These are explicit native ACF ammunition inputs, not hand-entered projectile masses or penetration values. ACF applies its own conversion, bounds, server constants, and damage rules. Bazooka and TOW reload in 4 seconds; Stinger reloads in 2 seconds; each holds one round. SMAW retains its existing reload animation behavior and can fire without aiming.

Bazooka and TOW arm for 3 seconds whenever drawn. Sprint is blocked during arming. Bazooka walking is reduced 25% during arming; TOW walking is reduced 50%. Once armed, walking returns to normal, and sprint is reduced 30% / 50%, respectively. Limits apply only while equipped and do not overwrite player speed properties. Hold aim to fire and guide; native wire constraints apply.

Stinger uses stock HL2 RPG models with hands. It has no extra launcher arming delay or movement penalties. Hold aim toward an ACF aircraft and fire; its native infrared seeker acquires after launch and continues independently when switching weapons. Native targeting scans contraptions, can acquire ground targets, has no team filter, and does not support every NPC/addon aircraft automatically. Uses HE with a Radio proximity fuze at 3 m and native 0.2-second post-launch fuze arming. Native seeker cones and countermeasures remain active.

Weapon selection now converts the shared ammunition definition rather than displaying placeholder masses/velocity. Stinger selection displays filler mass and blast radius: zero HE armor penetration is normal and is not zero explosive damage. ACF round networking is refreshed after conversion.

Requires current ACF-3 with integrated V2 missile classes and Wiremod. Adapter reference: ACF commit ace759766f384c9ba3a08ff844b7eb7ae221a92e. Bazooka/TOW keep the existing launcher model assets. Class filenames are retained for binds/saves. XM25 magazine remains 12.

Validation: modified Lua syntax and native ACF round conversions checked; exact requested ammunition inputs verified for all four weapons. Tests cover arming, sprint blocking, movement caps, reload completion/ammunition consumption, redeploy reset, and preserving the Stinger's independent seeker. Stinger converted HE data contains positive filler/projectile/propellant masses. Live GMod damage against aircraft/armor, animations, and prediction still require in-game verification; the reported no-damage behavior has not been reproduced in a running server here.


## Missile behavior repair

The shorter authored missile warheads now override the generic 1.5-caliber minimum length during native ammunition conversion. Tests assert final converted projectile/propellant dimensions, not only input fields: Bazooka 16/26 cm; TOW 20/18 cm. Native mass, jet, fuel, and flight calculations still apply. SMAW's APCR conversion is unchanged.

Wire guidance now traces the owner's current aim directly, retaining native wire-range and wire-break behavior, instead of relying on a held weapon acting as a Wire computer. Weapon selection shows converted lengths and guidance mode.

Stinger's fuze now calls ACF.Damage.createExplosion directly through the native missile HandleDetonation extension point. This bypasses the synthetic missile-self prop impact route. Native impact/proximity detection, fuze arming, motor shutdown, and missile removal remain active. An idempotence guard prevents duplicate HE explosions. Blast uses converted filler and casing mass and attributes damage to the owner. Contact blasts are moved 2 Source units along the impact normal to keep their origin outside the struck surface. This is ACF damage, not util.BlastDamage; the Source explosion effect is visual only.

Stinger retains native 0.2-second post-launch fuze arming: very close impacts can still be duds. Validate against a target at sufficient distance to arm. Code tests confirm exactly one call to the ACF damage routine; actual server damage and targeting still need live verification.

## VSS runtime diagnostic build vss-diag-5

Compared with PERSON00331/ACF-3-VSS-FORK at 96490fc9d8d3e50cf8c503f93aa66a6e9b1971c3. Its missile entity, round conversion, HE/HEAT ammunition, wire SACLOS, and missile-ammo injection files match the upstream files used for this adapter. Repeated the conversion and behavior tests against the VSS files. No VSS-specific incompatibility was established; this build gathers runtime evidence and is not a confirmed fix for the reported server failure.

After replacing the existing addon and restarting, an administrator can run `acf_infantry_missile_diagnostics` in the developer console. It records 120 seconds of diagnostics in the server console and the issuing administrator's console. Run it while holding an affected launcher, then fire each launcher and copy the `[ACF Infantry vss-diag-5]` lines. Reports include the loaded build marker, converted dimensions/filler, missile creation, guidance targets, native fuze arming/disabled state at detonation, HE damage dispatch, and ACF target health before/after the damage routine. If the command is unknown, the new server autorun file is not loaded. If a weapon says OLD/MISSING ADAPTER, its active definition is not this build.

The trace is opt-in and stops after 120 seconds, uses no chat messages, and never overrides an ACF damage-hook result. SMAW configuration and behavior are unchanged.

## vss-fix-6: missing missile self-filter

The handheld adapter initialized an empty rack missile list and did not add the launched missile itself to its collision filter. VSS's native Launch method normally copies a rack's loaded missile list into this filter, including the missile being fired. Without that entry, handheld flight traces could intersect the missile's own model after ghosting. This is consistent with repeated early detonations and unarmed Stinger duds, though live-server confirmation is still required.

All three handheld missile launchers now explicitly filter the missile itself, owner, and launcher before Launch, and synchronize the bullet filter. Native 0.2-second Stinger fuze arming remains unchanged. The build marker is vss-fix-6. A regression test reproduces the missing self-filter in the prior adapter and verifies the corrected pre-launch filter. No weapon ammunition values, reloads, movement settings, or SMAW code were changed.

Current reload times: ACF Bazooka 4 seconds; ACF TOW Launcher 4 seconds; ACF Stinger 2 seconds. Arming delays are unchanged.
