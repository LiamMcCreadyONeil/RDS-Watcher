## RDS Watcher

A lightweight Bash daemon that mirrors ICY stream metadata into an FM transmitter’s RDS encoder.

This script listens to a streaming audio source that exposes ICY metadata and forwards the rotating `StreamTitle` values to a transmitter’s TCP RDS control interface.

It is ideal for broadcast setups where playout automation (such as BreakawayOne) already rotates RDS messages in the stream.

Example metadata rotation:

- `Now Playing: Artist - Song`
- `Up Next: Artist - Song`

The script simply mirrors that rotation into the transmitter’s RDS system.

---

## Features

- Persistent ICY stream listener
- Automatically detects `StreamTitle` metadata changes
- Sends updates to a transmitter via TCP
- Deduplicates repeated metadata
- Handles automatic stream reconnection
- Optional Uptime Kuma monitoring
- Very low CPU usage
- No external runtime dependencies beyond standard Linux tools

---

## How it works

1. Connects to an ICY-compatible audio stream.
2. Requests metadata using the `Icy-MetaData: 1` header.
3. Continuously scans the stream for `StreamTitle` updates.
4. When metadata changes, sends:

   ```text
   TEXT=<metadata>
   ```

   to the transmitter’s TCP control port.

5. The transmitter updates the RDS RadioText accordingly.

---

## Requirements

The script relies only on common Linux utilities:

- `bash`
- `curl`
- `grep`
- `sed`
- `strings`
- `nc` (netcat)
- `stdbuf`

Most modern Linux distributions already include these.

---

## Installation

Clone the repository or download the script, then make it executable:

```bash
chmod +x rds-watcher-v2.sh
```

Optionally move it into your `$PATH`, for example:

```bash
sudo mv rds-watcher-v2.sh /usr/local/bin/rds-watcher-v2.sh
```

---

## Configuration

Edit the variables at the top of the script:

```bash
STREAM="http://your-stream-url"
TX="10.69.69.69"
PORT="5555"

KUMA_URL="https://statuspage.example/api/push/yourtoken"
```

- **`STREAM`**: Your ICY metadata audio stream.
- **`TX`**: IP address of the transmitter.
- **`PORT`**: TCP control port of the transmitter RDS interface.
- **`KUMA_URL`**: Optional Uptime Kuma push monitor endpoint.

---

## Running manually

From the directory containing the script:

```bash
./rds-watcher-v2.sh
```

Example output:

```text
2026-03-15 12:30:01 Connecting to stream...
2026-03-15 12:30:07 RDS updated: Coldplay - Yellow
2026-03-15 12:30:20 RDS updated: Up Next: Foo Fighters
```

---

## Running as a service (systemd)

Create a systemd service:

```bash
sudo nano /etc/systemd/system/rds-watcher.service
```

Add the following:

```ini
[Unit]
Description=RDS Watcher
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/rds-watcher-v2.sh
Restart=always
RestartSec=5
User=radio

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rds-watcher
sudo systemctl start rds-watcher
```

View logs:

```bash
journalctl -u rds-watcher -f
```

---

## Example use case

Broadcast playout system → BreakawayOne stream → RDS Watcher → Cobalt C-10 transmitter

```text
Automation
    ↓
BreakawayOne STL stream
    ↓
ICY metadata
    ↓
RDS Watcher
    ↓
TCP RDS injection
    ↓
FM transmitter RDS
```

---

## Why this exists

Many playout systems already generate RDS metadata in their audio streams.

However, transmitters (Aqua Cobalt C-10 in my case) often require RDS updates via TCP or serial commands.

This script bridges that gap by converting ICY metadata into transmitter RDS commands.

---

## Notes

- The script intentionally keeps a persistent stream connection for minimal latency.
- Typical delay vs VLC is around 1–3 seconds.
- RDS messages are truncated to 64 characters.

---

## License

MIT License. Use freely in broadcast environments.
