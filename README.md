# ntc-livestock

Cows on the back roads. A free, standalone FiveM resource that puts a herd of livestock across quiet country roads. Slow down, sound the horn, and they scatter.

No framework, no database, no dependencies. Works on ESX, QBCore, Qbox or a bare server.

## Features

- Random herds appear ahead of drivers on rural backroads, out of sight, never on highways, junctions or in tunnels
- Fixed herds at coordinates you choose, always there when a player comes near
- Hold the horn within range and the herd runs off the road
- Herds ignore engine noise, so they block the road until someone honks
- Client-side only: no server script, no network traffic, no entities left behind
- Everything tunable in `config.lua`

## Install

1. Download or clone this repository into your `resources` folder as `ntc-livestock`.
2. Add to `server.cfg`:

   ```cfg
   ensure ntc-livestock
   ```

3. Restart the server, or run `refresh` then `ensure ntc-livestock` in the console.

## Configuration

All settings are in `config.lua`.

| Setting | Default | Meaning |
|---|---|---|
| `Config.Models` | `a_c_cow` | Animal models. One is picked per herd. Add addon models here. |
| `Config.FlockSize` | `{ 5, 9 }` | Minimum and maximum animals per herd. |
| `Config.Chance` | `0.12` | Chance of a random herd per check. |
| `Config.CheckMs` | `6000` | Milliseconds between checks. |
| `Config.CooldownMs` | `240000` | Minimum milliseconds between two random herds for one player. |
| `Config.Ahead` | `170.0` | Metres down the road the herd appears. |
| `Config.MinSpeed` | `8.0` | Minimum vehicle speed in m/s for a random herd. |
| `Config.MaxDensity` | `4` | Highest road traffic density (0-15) that counts as a backroad. |
| `Config.HornControl` | `86` | Control that scatters the herd. 86 is the vehicle horn. |
| `Config.HornRange` | `35.0` | Metres within which the horn works. |
| `Config.RuralZones` | Blaine County zones | Zone names where random herds can appear. |
| `Config.Spots` | one example | Fixed herds as `vec4(x, y, z, road heading)`. |
| `Config.Debug` | `false` | Print skipped fixed spots to the F8 console. |

### Adding a fixed herd

Stand on the road, note your coordinates and the heading along the road, and add a line:

```lua
Config.Spots = {
    vec4(1498.88, 1550.54, 109.76, 356.3),
    vec4(-1234.5, 2345.6, 78.9, 90.0),
}
```

A spot that is not on a backroad is skipped. Set `Config.Debug = true` to see the reason in the F8 console.

### More herds, or fewer

Raise `Config.Chance` or lower `Config.CooldownMs` for more. Set `Config.Chance = 0` to keep only the fixed herds.

## How it works

Every few seconds the script checks whether the player is driving a car, above the minimum speed, in a rural zone, on a low-traffic road node. If the roll succeeds it finds a road node ahead, confirms that is also a backroad, and spawns the herd there. The herd is removed when the player drives away, two minutes pass, or 25 seconds after it is scattered.

## Performance

The script idles in a 1.5 second loop. It runs every frame only while a herd exists and the player is within 60 metres, to catch the horn press.

## Limitations

- Herds are local to each player. A passenger, or another driver nearby, does not see the same herd.
- Random herds are for cars only. Bikes, boats and aircraft do not trigger them.
- GTA V has no sheep model. Add a streamed addon model to `Config.Models` if you want sheep.

## Licence

MIT. See [LICENSE](LICENSE).

By [rpatty-dev](https://github.com/rpatty-dev).
