#!/usr/bin/env python3
from __future__ import annotations

import argparse
import asyncio
import re
import sys

from netaudio._common import _command_context, filter_devices
from netaudio.dante.const import SERVICE_ARC
from netaudio.dante.device_commands import DanteDeviceCommands

REAPER_CHANMAP_PATH = "/home/cody/.fasttrackstudio/Reaper/ChanMaps/THEBATTLESHIP.ReaperChanMap"


def parse_reaper_chanmap(path: str) -> dict[int, str]:
    names: dict[int, str] = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"name(\d+)=(.*)", line.strip())
            if m:
                names[int(m.group(1))] = m.group(2)
    return names


async def wait_for_device(device_name: str, attempts: int = 20, delay: float = 1.0):
    for _ in range(attempts):
        async with _command_context() as (devices, _send):
            filtered = {
                server_name: device
                for server_name, device in filter_devices(devices).items()
                if device.name == device_name or server_name == device_name
            }
            if filtered:
                return filtered
        await asyncio.sleep(delay)
    return {}


def _arc_port(device) -> int:
    # Devices advertise their ARC port over mDNS; the Dante default is 4440 but
    # Inferno-AoIP relocates it (e.g. 4400) when ALT_PORT is set, so always
    # prefer what the device announced.
    for service in (device.services or {}).values():
        if service.get("type") == SERVICE_ARC:
            port = service.get("port")
            if port:
                return port
    return 4440


async def set_channel_name(device, send, channel_number: int, channel_type: str, name: str):
    commands = DanteDeviceCommands()
    packet, _ = commands.command_set_channel_name(channel_type, channel_number, name)
    await send(packet, device.ipv4, _arc_port(device))


async def set_single(device_name: str, channel_number: int, channel_type: str, name: str) -> int:
    devices = await wait_for_device(device_name)
    if not devices:
        print(f"Device {device_name} did not appear", file=sys.stderr)
        return 1

    async with _command_context() as (_all_devices, send):
        filtered = {
            sn: d for sn, d in filter_devices(_all_devices).items()
            if d.name == device_name or sn == device_name
        }
        if not filtered:
            print(f"Device {device_name} disappeared before setting channel", file=sys.stderr)
            return 1

        server_name, device = next(iter(filtered.items()))
        print(f"Setting {channel_type} channel {channel_number} to '{name}'...")
        try:
            await set_channel_name(device, send, channel_number, channel_type, name)
        except Exception as exc:
            print(f"  Error: {exc}", file=sys.stderr)
            return 1
        print("  OK")
        return 0


async def run(device_name: str, chanmap_path: str, channel_type: str, dry_run: bool, start: int, end: int):
    names = sorted(parse_reaper_chanmap(chanmap_path).items())
    if not names:
        print(f"No channel names found in {chanmap_path}", file=sys.stderr)
        return 1

    if end <= 0:
        end = len(names)
    selected = names[start - 1 : end]

    print(f"Found {len(names)} channel names in {chanmap_path}")
    print(f"Processing entries {start}..{start + len(selected) - 1}")

    devices = await wait_for_device(device_name)
    if not devices:
        print(f"Device {device_name} did not appear", file=sys.stderr)
        return 1

    async with _command_context() as (_all_devices, send):
        filtered = {
            sn: d for sn, d in filter_devices(_all_devices).items()
            if d.name == device_name or sn == device_name
        }
        if filtered:
            server_name, device = next(iter(filtered.items()))
        else:
            print(f"Device {device_name} disappeared before renaming", file=sys.stderr)
            return 1

        for ch, name in selected:
            channel_number = ch + 1
            print(f"Channel {channel_number}: {name}")
            if dry_run:
                continue

            try:
                await set_channel_name(device, send, channel_number, channel_type, name)
            except Exception as exc:
                print(f"  Error: {exc}", file=sys.stderr)
                return 1
            print("  OK")

    return 0


def main():
    parser = argparse.ArgumentParser(description="Set Dante channel names from ReaperChanMap")
    parser.add_argument("--device", default="THEBATTLESHIP", help="Dante device name")
    parser.add_argument("--chanmap", default=REAPER_CHANMAP_PATH, help="Path to ReaperChanMap")
    parser.add_argument("--channel-type", default="tx", choices=("tx", "rx"), help="Dante channel direction to rename")
    parser.add_argument("--start", type=int, default=1, help="1-based index of the first chanmap entry to process")
    parser.add_argument("--end", type=int, default=0, help="1-based index of the last chanmap entry to process (0 = all)")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without executing")
    parser.add_argument("--set-channel", type=int, help="Set a single channel number (1-based)")
    parser.add_argument("--name", help="Name to set when using --set-channel")
    args = parser.parse_args()

    if args.set_channel and args.name:
        return asyncio.run(set_single(args.device, args.set_channel, args.channel_type, args.name))
    return asyncio.run(run(args.device, args.chanmap, args.channel_type, args.dry_run, args.start, args.end))


if __name__ == "__main__":
    raise SystemExit(main())
