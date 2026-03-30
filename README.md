# Hestia Linux

Systemd units and sleep script for the original Linux implementation of Hestia's smart sleep/wake cycle. Hestia is a Lenovo ThinkPad X1 Carbon 5th Gen embedded in a door, running as the brain of **The Monidoor** a touchscreen calendar, kitchen entertainment system, scrolling picture frame, and digital hearth of the home.

This repo is archived. Hestia now runs Windows 10 LTSC. The Windows implementation is at [github.com/foodbark/hestia](https://github.com/foodbark/hestia). The full backstory is at [foodbark.io](https://foodbark.io/posts/the-big-sleep-and-wake-cycle/).

## Hardware

| | |
|---|---|
| **Machine** | Lenovo ThinkPad X1 Carbon 5th Gen (20HRCTO1WW) |
| **OS** | Confrimed functionality on Ubuntu 24.04.4 LTS (Noble Numbat) and Fedora 43 |
| **BIOS** | N1MET78W (1.63) |
| **CPU** | Intel i7-7500U |
| **RAM** | 16GB |
| **Network** | WiFi only — Intel 8265 (no RJ45) |
| **Sleep states** | S3 (Standby) and Hibernate available |
| **Display** | ASUS BE24ECSBT 23.8" multi-touchscreen monitor (laptop lid always closed) |

## How It Works

Two systemd timers fire at bedtime and trigger a oneshot service that runs `smart-suspend.sh`. The script calculates the correct wake time based on the day of week, writes it directly to the hardware RTC via `rtcwake`, and suspends the system. On wake, the RTC alarm fires and the machine comes back up — no scheduled task, no wake timer registry, just hardware.

```
sleep-at-midnight.timer  (Sun–Thu 00:00)  ──┐
                                              ├──▶  sleep-at.service  ──▶  smart-suspend.sh
sleep-at-1am.timer       (Fri–Sat 01:00)  ──┘
```

## Files

| File | Description |
|---|---|
| `smart-suspend.sh` | Calculates wake time based on day of week, sets RTC alarm via `rtcwake`, suspends via `systemctl suspend`. |
| `sleep-at.service` | Oneshot systemd service that runs `smart-suspend.sh`. |
| `sleep-at-midnight.timer` | Fires Sun–Thu at midnight. |
| `sleep-at-1am.timer` | Fires Fri–Sat at 1am. |

## Schedule

| Night | Sleep | Wake |
|---|---|---|
| Sun–Thu | Midnight | 7am |
| Fri–Sat | 1am | 9am |

## Installation

```bash
# Copy script
sudo cp smart-suspend.sh /usr/local/bin/smart-suspend.sh
sudo chmod +x /usr/local/bin/smart-suspend.sh

# Copy systemd units
sudo cp sleep-at.service /etc/systemd/system/
sudo cp sleep-at-midnight.timer /etc/systemd/system/
sudo cp sleep-at-1am.timer /etc/systemd/system/

# Enable and start timers
sudo systemctl daemon-reload
sudo systemctl enable --now sleep-at-midnight.timer
sudo systemctl enable --now sleep-at-1am.timer

# Verify timers are active
systemctl list-timers sleep-at*
```

## Logging

`smart-suspend.sh` logs to `/var/log/hestia-sleep-wake.log`.

```bash
tail -20 /var/log/hestia-sleep-wake.log
```

## Why This Is Simpler Than Windows

Linux exposes direct hardware RTC access via `/sys/class/rtc/rtc0/wakealarm`. `rtcwake` writes a Unix timestamp to that file and the hardware alarm fires regardless of sleep state S3, S4, doesn't matter. One command sets the alarm and suspends.

Windows does not expose direct RTC access. Wake timers on Windows are registered with the kernel and only survive Hybrid Sleep (S3), not full hibernate (S4). This requires careful power plan configuration to keep the machine in S3 long enough for the timer to fire. See the Windows repo for the full details.
