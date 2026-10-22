# Gun and launcher safety

Press B while holding an ACF Infantry gun or launcher to toggle its safety. The HUD displays SAFETY ON/OFF. Safety starts off and its state stays with that weapon entity while holstered. It blocks primary fire before shot/ammunition logic, without blocking sights, reloads, or existing fire-mode controls. Existing in-flight missiles are unaffected. Release the trigger after switching safety off before firing again. Grenades, health stim, suit armor, EPO, and thermal goggles do not have this safety.

The toggle is server-authoritative, rate-limited, and only operates on the requesting living player's active weapon. No chat messages are sent. The optional console command is `acf_infantry_toggle_safety`, which can also be bound to a key. B is the default shortcut while normal gameplay input is active.

Checks cover toggling, rate limiting, fire input suppression, fresh-trigger requirement, independent weapon states across switching, dead-player rejection, exclusion of grenade and utility bases, and the primary-attack guard shared by the gun/launcher implementations. Live HUD, sound, key handling and prediction still need an in-game check.
