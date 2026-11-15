# Changes: enemies, spawner, house, lives, shop, sound hooks, balance

Branch: `enemy-spawner-house-shop` (on top of `main` at `48c1117 water`).
Built for Godot 4.7.2. Nothing here edits `scripts/player.gd`, `scenes/player.tscn`
or `scenes/levels/island.tscn`, so it should merge cleanly with work on those.

## What was added

| Area | Files | What it does |
| --- | --- | --- |
| Shared state | `scripts/game.gd` (autoload `Game`) | Money, wave, house lives, owned weapons, fence, shop buy rules, "is this spot grass?" check, cow shove on the player, game over. |
| Enemies | `scripts/enemy.gd`, `scenes/enemies/chicken.tscn`, `cow.tscn` | Walk to the house, get knocked back by the player's swing, drown in the water for money. No health. Stats are set per scene in the Inspector. |
| Spawner | `scripts/enemy_spawner.gd`, `scenes/enemy_spawner.tscn`, `scenes/boat.tscn` | Runs the 5 waves. Boats park in the water at the shore and enemies land next to them. |
| House + lives | `scripts/house.gd`, `scenes/house.tscn`, `scripts/hearts.gd` | House takes a hit when an enemy reaches it. 3 lives shown as hearts. Fence ring blocks one hit. |
| Shop panel | `scripts/shop.gd`, `scenes/ui/shop.tscn` | Panel that pops up by itself before wave 1 and after every cleared wave (pop-in animation). Buy hoe, axe or fence, "Start wave N", or "Back to the farm". Buttons ignore presses for 0.4 s after it opens, so mashing Space at the last enemy cannot buy or start a wave by accident. |
| Pop-up shop stall | `scripts/shop_stall.gd`, `scenes/shop_stall.tscn` | A little market stall (two tables with the can, hoe, axe and a milk jar) that pops in on grass next to the house at round end and leaves when the next wave starts. Solid while it is there. Shows "Press E to shop" when you are within 240 px. |
| HUD | `scripts/hud.gd`, `scenes/ui/hud.tscn` | Wave, money, weapon, enemies left, hearts, fence icon, "Wave N" banner, game over screen with Play again. |
| Wiring | `scripts/main.gd`, `scenes/main.tscn` | Adds the house, stall, spawner, HUD and shop next to the island and connects them. Handles the E and Escape keys. |
| Sound hooks | `scripts/sfx.gd` (autoload `Sfx`) | `Sfx.play("splash")` etc. Plays nothing until sound files are added (see below). |
| Settings | `project.godot` | Registers the `Game` and `Sfx` autoloads and adds a new `interact` input action on **E**. |
| Credits | `CREDITS.md` | Sprout Lands credit, parked for an end-of-game credits screen. |

## How it fits together

- `main.gd` hands the island's grass tilemap, the player and the house to `Game`.
  **Land = a grass tile exists at that spot; anything else is water.** Enemies drown when
  they were smacked and are no longer on grass. The player loses ("You fell off the island!")
  the same way during a wave (checkbox `lose_when_player_leaves_island` on the `Main` node).
- The player's script is not changed. Each enemy watches the player's existing
  `is_attacking` and `last_direction` and takes a hit when a swing starts in front of it
  (reach 130 px, in a cone). Weapon strength comes from `Game.weapon`.
- Knockback = weapon level minus the enemy's resistance, never below `MIN_KNOCK_LEVEL`.
  Launch speed = level x 1024, slide distance = speed / 4 (256 px per level).
- **Shop flow.** At the start and whenever a round ends the stall pops up next to the house
  **and** the shop panel opens by itself. Close the panel (button "Back to the farm", **E**, or
  **Esc**), walk around, and press **E** next to the stall to reopen it. The next wave only
  starts from the panel's "Start wave" button, and the stall leaves when it does.
  The stall picks the first free grass spot out of right, left, below, above the house.
- Enemies that were never hit earn nothing, even if they reach the water.
- The fence blocks the next hit on the house and then disappears. It can be bought again.
- Weapons are bought once and kept.
- Payout per drowning: chicken $5, cow $10, plus 20% per wave after wave 2
  (wave 3: $6/$12, wave 4: $7/$14, wave 5: $8/$16).

## Balance changes

Starting point was the numbers in the design doc and coding guide. They were tuned by playing
the real game with a bot, not by hand (see "How it was tested"). All values are in one place each.

| Value | File | Design doc / guide | Now | Why |
| --- | --- | --- | --- | --- |
| Hoe price | `game.gd` `WEAPON_PRICES` | $30 | **$60** | At $30 it was bought after wave 1; the doc says the shop opens at wave 3 with "hoe or fence". |
| Axe price | `game.gd` `WEAPON_PRICES` | $60 | **$120** | Affordable right after wave 3 so it is available for the hard waves 4-5 ("axe is key"), but not before. |
| Fence price | `game.gd` `FENCE_PRICE` | $25 | **$30** | Keeps fence vs saving for the axe a real choice. |
| Weak weapon on a heavy enemy | `game.gd` `MIN_KNOCK_LEVEL` | 0.25 | **0.75** | With 0.25 the watering can moved a cow only 64 px, so wave 2 (first cow, can only) was a wall. Now 192 px (a chicken takes 256). |
| Wave 2 cows | `enemy_spawner.gd` `WAVES` | 2 | **1** | Gentler first cow. |
| Wave 3 | `WAVES` | 10 chickens, 4 cows | **11, 3** | Smoother ramp. |
| Wave 4 | `WAVES` | 12, 6 | **12, 5** | First wave with boats on two sides. |
| Wave 5 | `WAVES` | 16, 8 | **14, 6** | Was close to unwinnable with 4 boats. |
| Spawn gap | `enemy_spawner.gd` `SPAWN_INTERVALS` | one fixed value | **1.2 / 1.1 / 1.0 / 1.0 / 0.9 s** | Slower early, faster at the end. |
| Chicken speed | `enemy.gd` `speed` | fast | **125** | Slightly easier to intercept. |
| Cow speed | `scenes/enemies/cow.tscn` | slow | **50** | More time to push a cow to the shore. |

Unchanged: 3 house lives, hoe knockback 2, axe knockback 3, cow resistance 1, cow shove knockback 2,
boats per wave (1, 2, 2, 3, 4), two-sided landing from wave 4, payouts.

### Result of the last round (10 bot runs per skill level)

| | Wins | Typical outcome |
| --- | --- | --- |
| Good bot | 9 of 10 | Waves 1-4 clean, wave 5 costs about 0.3 lives, about 3 lives left at the end |
| Average bot | 1 of 10 | Wave 2 (cow with the can) costs 1 life, dies mostly at waves 4-5 |

A skilled player should win most of the time; a clumsy one will usually lose around waves 4-5.
Waves 1-3 are short and forgiving on purpose (tutorial). **These are bot numbers, not human
playtests.** The first real playtest should decide whether to nudge `WAVES`, prices and
`MIN_KNOCK_LEVEL`.

## How to tune

- Money and shop: `WEAPON_PRICES`, `FENCE_PRICE` in `scripts/game.gd`.
- How far things fly: `KNOCK_UNIT`, `MIN_KNOCK_LEVEL`, `KNOCK_DECAY` in `scripts/game.gd`.
- Waves, boats, pacing: `WAVES`, `BOATS_PER_WAVE`, `SPAWN_INTERVALS`, `TWO_SIDES_FROM_WAVE`
  in `scripts/enemy_spawner.gd`.
- One enemy type: select the node in `scenes/enemies/cow.tscn` or `chicken.tscn` and edit
  `speed`, `knockback_resistance`, `bounty`, `player_knockback` in the Inspector.
- Swing reach and cone: `ATTACK_REACH`, `ATTACK_ARC` in `scripts/enemy.gd`.
- House lives: `HOUSE_MAX_LIVES` in `scripts/game.gd` (hearts redraw automatically).

## Sound effects

`scripts/sfx.gd` is wired to these events. Drop a file named exactly like the list into
`assets/sounds/` (`.ogg`, `.wav` or `.mp3`) and it plays. Missing files are silent, no errors.

| Name | Plays when |
| --- | --- |
| `swing` | the player starts an attack |
| `hit` | a swing hits an animal |
| `splash` | an animal drowns |
| `house_hit` | an animal reaches the house and the house loses a life |
| `fence_break` | an animal reaches the house and the fence takes the hit |
| `buy` | something is bought in the shop |

Five of the six are in `assets/sounds/` (CC0 sounds by Kenney, sources in `CREDITS.md`): `swing`,
`hit`, `house_hit`, `fence_break`, `buy`. **`splash` is still missing** (the Kenney packs have no
water sound) and stays silent until `assets/sounds/splash.ogg` is added. The sounds were picked by
file name, not by ear, so audition them; to swap one, replace the file keeping its name.
Record the source and licence of any new sound in `CREDITS.md`.

## How it was tested

- Godot 4.7.2 headless: imports with no errors and the main scene boots.
- A scripted playthrough of the real `main.tscn` checked shop buying, the fence, payouts,
  house destroyed, game over and the pause. It was written for the original numbers and
  should be re-run after the balance changes (its money and enemy-count asserts are out of date).
- A bot played whole runs through the real player script (same speed, same attack timing,
  8-direction keyboard-style movement, aiming at the nearest shore) at two skill levels.
  That is where the balance numbers above come from.
- A second scripted check covers the stall and panel: stall on grass and clear of the fence,
  pops up at round end with the panel, E opens/closes it, Esc and the "Back to the farm" button
  close it, the press-lock ignores an accidental "Start wave", and the stall is gone and
  non-solid during a wave. All 25 checks pass.
- Screenshots of the running game were checked for the house, fence, hearts, boats, stall, shop and
  game over screen.
- After adding the stall, the balance bot still wins 8 of 8 runs at the good level, so the
  stall and press-lock did not change how a game plays out.

## Not done yet / open questions

- **Splash sound** is missing (see above). OpenGameArt has CC0 options ("Ocean splash",
  "40 CC0 water / splash / slime SFX") but its server refuses automated downloads, so it has to be
  downloaded in a browser and saved as `assets/sounds/splash.ogg`.
- **Boss (Giga Cow) and the ship arena** are not built. Clearing wave 5 currently shows the win screen.
- **Swing animation is always the watering can**, whatever weapon is equipped. That is in
  `player.tscn`/`player.gd` (a teammate's files). The weapon's strength is already used correctly.
- **The house sprite is the pack's chicken house.** The Basic pack has no ready-made house.
  The pack's wooden-house wall and roof tiles could be assembled into a real one.
- **Money has few uses after the axe** (only the fence). If playtests show piles of unused
  money, options are stacking fences, a second axe tier or healing the house between waves.
- **Design doc open questions** answered here by choice: fence blocks one hit and can be rebought;
  house has 3 lives; weapons are bought once and kept; chickens can't knock the player; only cows can.
  Change in `game.gd` / `enemy.gd` if the team decides otherwise.
