# Smoke and fire grenades

Two spawnable weapons are added to the ACF Infantry Q-menu category:

| Weapon | CSS models | Behavior |
|---|---|---|
| ACF Smoke Grenade | v_eq_smokegrenade / w_eq_smokegrenade | Two-second fuse, native ACF_Smoke effect, approximately 20-second cloud |
| ACF Fire Grenade | v_eq_fraggrenade / w_eq_fraggrenade | Two-second fuse, ten-second burning area, ACF explosion/flame assets |

Both use CSS viewmodel arms and pull-pin/throw animations. CSS has no Molotov, so the fire grenade uses its HE grenade model. CSS content must be mounted on the server and clients; the addon does not redistribute those models. ACF-3 VSS and its dependencies remain required.

Hold primary fire to pull the pin; release to throw. The pin animation takes 0.8 seconds, then the throw releases the projectile after 0.2 seconds. The fuse begins when the projectile spawns, not while held (no cooking). Holstering a held grenade cancels priming; holstering during the brief throw-release window is blocked. Another grenade readies automatically if reserve ammo exists, or press reload when empty. Each starts with three total grenades. Smoke and fire use separate reserve ammunition types (six reserve maximum). No movement penalty or chat messages. The HUD uses the existing ACF Infantry theme. Each player may have at most six active grenade projectiles/fire areas; failed throws do not consume ammo.

Smoke uses the exact effect payload convention of VSS's smoke ammunition: Scale 1.5, no white-phosphorus filler, gray smoke, 6 cm effect caliber. The native particle effect determines cloud size, deployment, lifetime, wind and client density. It is visual concealment only: no damage or custom NPC/IR/FLIR seeker blocking is added.

Fire is custom server behavior using existing ACF effect assets, not a native ACF Molotov round. It creates up to nine ground patches. Each has a 60-Source-unit damage radius, arranged up to 100 units from the grenade. Walls, steep/vertical surfaces, and water constrain placement; line of sight and water checks also constrain damage. Burning lasts ten seconds. Characters receive 15 HP/second before ordinary damage hooks and armor; overlapping patches from one grenade do not multiply this rate. Separate grenades can stack. ACF props receive low-penetration thermal damage through VSS DamageResult/dealDamage (4 cm² of damage area per second, 1 mm penetration), so heavy armor strongly resists it. These are gameplay settings, not an HE blast or realistic material combustion model. Damage is attributed to the thrower, uses native server damage hooks, and has no custom team immunity. Water extinguishes fire. The fire grenade's small initial ACF explosion effect is visual only; damage comes from the timed patches.

The physical projectile is acf_infantry_grenade. Flame particles reuse the flamelet materials used by ACF's explosion effect. Fire emits particles locally with a distance cutoff and releases its emitter/sound on removal. Map cleanup and entity removal stop the server damage loop.

Validation: all seven new Lua files compile. Mocked behavior checks cover pin/release/throw timing, ammunition use/refill, spawn failure and active-grenade cap, death cancellation, one smoke effect per burst, submerged fire rejection, burn rate, non-stacking patches, wall/water damage checks, ACF prop damage dispatch, fire expiration, and ground patch placement. Live CSS animation/model appearance, physics, smoke rendering, and multiplayer prediction require in-game verification. Existing weapon files and the working vss-fix-6 missile adapter are unchanged.

## Nerve gas addition

**ACF Nerve Gas Grenade** (`weapon_acf_nervegas`) uses `models/weapons/w_eq_flashbang.mdl` as its world/projectile model and the matching CSS `v_eq_flashbang.mdl` for first-person arms and animations. Smoke continues to use `models/weapons/w_eq_smokegrenade.mdl`; fire continues to use `models/weapons/w_eq_fraggrenade.mdl`.

The gas grenade shares the existing hold/release throw behavior, two-second fuse, and three-grenade starting inventory. It has a separate ammo type. Its green ACF smoke visual lasts approximately 15 seconds; server exposure lasts 15 seconds with a 180-Source-unit (~4.57 m) radius. Particle boundaries are approximate. Characters in line of sight receive 5 HP/second before ordinary damage hooks, in quarter-second ticks, attributed to the thrower. Gas does not damage ACF props. Separate clouds can stack damage.

Exposed players have both forward/side command values and WASD button bits reversed (W ↔ S, A ↔ D). Analog movement along those axes reverses too. Aiming, jump, sprint, use, and other button bits are preserved. Reversal lasts while exposed and up to 0.4 seconds afterward; it works while holding other weapons. It does not reverse vehicle driving. Death/respawn clear it. Walls block exposure; substantially submerged characters are unaffected, and a grenade bursting underwater produces no gas cloud. This is a fictional gameplay debuff, not a simulation of any real chemical agent. No chat messages are added.

Added tests verify gas damage/exposure timing, wall blocking, expiry, both reversed movement axes and button mappings, preservation of other controls, and vehicle/death/respawn handling. Live client/server prediction, CSS assets, and particle appearance still need an in-game check. Existing working missile and SMAW files are unchanged.
