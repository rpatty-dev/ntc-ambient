<p align="center">
  <img src="logo.png" alt="ntc-ambient" width="640">
</p>

# ntc-ambient

Cows on the back roads. A free, standalone FiveM resource that puts a herd of livestock across quiet country roads. Slow down, sound the horn, and they scatter.

Herds are synced: every player nearby sees the same animals in the same place, and sees them run when someone honks.

No framework, no database, no dependencies. Works on ESX, QBCore, Qbox or a bare server.

## Features

- Random herds appear ahead of drivers on rural backroads, out of sight, never on highways, junctions or in tunnels
- Fixed herds at coordinates you choose, raised when a player comes near
- Fully synced: server-owned networked animals, one herd for everyone
- Hold the horn within range and the herd runs off the road, for all players
- Herds ignore engine noise, so they block the road until someone honks
- Server enforces cooldowns, herd limits and spacing, so a modified client cannot flood the map
- The server removes every animal it creates: on expiry, when nobody is near, and when the resource stops
- More than 30 settings in `config.lua`

## Requirements

- OneSync enabled (the default on current FXServer builds)

## Install

1. Download or clone this repository into your `resources` folder as `ntc-ambient`.
2. Add to `server.cfg`:

   ```cfg
   ensure ntc-ambient
   ```

3. Optional, to use the test command:

   ```cfg
   add_ace group.admin command.livestock allow
   ```

4. Restart the server, or run `refresh` then `ensure ntc-ambient` in the console.

## Test it

Run `/livestock` in game with the permission above. A herd appears 25 metres in front of you. Drive up and hold the horn.

## Configuration

All settings are in `config.lua`.

### The herd

| Setting | Default | Meaning |
|---|---|---|
| `Config.Models` | `a_c_cow` | Animal models. One is picked per herd. Add addon models here. |
| `Config.FlockSize` | `{ 5, 9 }` | Minimum and maximum animals per herd. |
| `Config.SpreadAlong` | `10.0` | Metres the herd spreads each way along the road. |
| `Config.SpreadSide` | `3.5` | Metres each way across the road. |
| `Config.WanderRadius` | `7.0` | Metres the animals wander from the herd centre. |
| `Config.Invincible` | `false` | Animals cannot be killed or run over. |

### Random herds: `Config.Random`

| Setting | Default | Meaning |
|---|---|---|
| `Enabled` | `true` | Turn random herds on or off. |
| `Chance` | `0.12` | Chance of a herd per check. |
| `CheckMs` | `6000` | Milliseconds between checks. |
| `CooldownSec` | `240` | Seconds before the same player can trigger another herd. |
| `Ahead` | `170.0` | Metres down the road the herd appears. |
| `MinSpeed` | `8.0` | Minimum vehicle speed in m/s. |
| `MaxDensity` | `4` | Highest road traffic density (0-15) that counts as a backroad. |
| `CarsOnly` | `true` | Set `false` so bikes, quads and trucks trigger herds too. |
| `Hours` | `false` | `{ from, to }` in game hours, for example `{ 6, 21 }`. `false` means any time. |
| `Zones` | Blaine County zones | Zone names where random herds can appear. |

### Fixed herds: `Config.Spots` and `Config.Fixed`

| Setting | Default | Meaning |
|---|---|---|
| `Config.Spots` | one example | Herd positions as `vec4(x, y, z, heading along the road)`. |
| `Range` | `200.0` | A player this close raises the herd. |
| `LifetimeSec` | `600` | Seconds a fixed herd stays if nobody shifts it. |
| `RespawnSec` | `300` | Seconds before it can return, and only after the area has been empty. |

### The horn: `Config.Horn`

| Setting | Default | Meaning |
|---|---|---|
| `Enabled` | `true` | Set `false` and the herd never moves. |
| `Control` | `86` | Control that scatters the herd. 86 is the vehicle horn. |
| `Range` | `35.0` | Metres from the herd centre. |
| `DriverOnly` | `true` | Only the driver can scatter the herd. |
| `FleeDistance` | `80.0` | Metres the animals run. |
| `DespawnSec` | `25` | Seconds after scattering before the herd is removed. |

### Server limits: `Config.Limits`

| Setting | Default | Meaning |
|---|---|---|
| `MaxHerds` | `6` | Random herds alive at once, server wide. |
| `MinGap` | `300.0` | Metres between two herds. |
| `LifetimeSec` | `180` | Seconds a random herd lives. |
| `DespawnDistance` | `260.0` | A herd with no player this close is removed. |
| `TickMs` | `5000` | Milliseconds between server sweeps. |

### Tools

| Setting | Default | Meaning |
|---|---|---|
| `Config.TestCommand` | `'livestock'` | Admin command name. `false` removes the command. |
| `Config.Debug` | `false` | Print spawns, removals and scatters to the server console. |

## How it works

1. Each driver's client rolls a chance every few seconds. On a success it checks that the car is in a rural zone on a low-traffic road, then finds a road point ahead that is also a backroad.
2. The client sends that point to the server. Road data only exists on clients, so the client proposes and the server decides.
3. The server checks the player's cooldown, their distance from the point, the herd limit and the gap to other herds. If all pass it creates the animals as networked entities.
4. Whichever client owns an animal gives it its behaviour: wander near the herd centre and ignore engine noise.
5. A horn press near the herd is sent to the server. The server validates it and marks the herd as scattered, and the owning clients make the animals flee.
6. The server removes the herd when its time runs out, when it has been scattered, or when no player is near.

## Performance

- Client, no herd nearby: one loop every 2 seconds that checks a cached table, and one loop every 6 seconds that rolls a number.
- Client, herd within 150 metres: a light check every 400 milliseconds.
- Client, driving within horn range: one control check per frame, until the horn is pressed.
- Server: one sweep every 5 seconds, skipped when there are no herds and no fixed spots.
- Herd state reaches clients through one global state bag, sent only when a herd appears, scatters or is removed.

## Limitations

- GTA V has no sheep model. Add a streamed addon model to `Config.Models` if you want sheep.
- The server cannot read road data, so fixed spots are not checked against the road. Place them on the road yourself.

## Licence

MIT. See [LICENSE](LICENSE).

By [rpatty-dev](https://github.com/rpatty-dev).
