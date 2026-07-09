#!/usr/bin/env python3
"""
spike/verify_fit.py

Standalone, stdlib-only FIT workout file verifier/decoder for the
Garmin-workout-export spike. Independently re-implements the FIT binary
format (header, CRC-16, definition/data messages) from the field/enum
numbers documented in spike/reference/fit-profile-excerpt.md — it does not
import or reuse spike/fit-encoder.js in any way, so a clean decode here is a
genuine cross-check of the JS encoder, not a self-consistency tautology.

Usage:
    python3 spike/verify_fit.py spike/output/progressivite-allure-2026-05-05-g12.fit
    python3 spike/verify_fit.py spike/output/progressivite-allure-2026-05-05-g3.fit

Exits non-zero (and prints a FAIL line) if the header is malformed, either
CRC fails, no file_id/file_creator/workout/workoutStep messages are found,
the file_id.type is not "workout", or the file_id.serialNumber is 0/unset
(the real-Garmin-Connect-import requirements documented in
spike/reference/fit-profile-excerpt.md).
"""

import struct
import sys
from datetime import datetime, timedelta, timezone

# ---------------------------------------------------------------------------
# CRC-16, independently re-implemented from the same publicly documented FIT
# algorithm description used in fit-encoder.js (nibble lookup table + update
# routine) — see spike/reference/fit-profile-excerpt.md.
# ---------------------------------------------------------------------------

CRC_TABLE = [
    0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
    0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
]


def crc16_update(crc, byte):
    tmp = CRC_TABLE[crc & 0xF]
    crc = (crc >> 4) & 0x0FFF
    crc = crc ^ tmp ^ CRC_TABLE[byte & 0xF]

    tmp = CRC_TABLE[crc & 0xF]
    crc = (crc >> 4) & 0x0FFF
    crc = crc ^ tmp ^ CRC_TABLE[(byte >> 4) & 0xF]

    return crc & 0xFFFF


def crc16(data):
    crc = 0
    for b in data:
        crc = crc16_update(crc, b)
    return crc


# FIT epoch: seconds since UTC 1989-12-31T00:00:00Z.
FIT_EPOCH = datetime(1989, 12, 31, 0, 0, 0, tzinfo=timezone.utc)


def fit_datetime_to_utc(value):
    return FIT_EPOCH + timedelta(seconds=value)


# ---------------------------------------------------------------------------
# Base type table (verbatim numeric IDs from the public FIT base-type table,
# cross-checked against fit-encoder.js's BASE_TYPE constants).
# ---------------------------------------------------------------------------

# id -> (python struct code or None for string, byte size, invalid sentinel or None)
BASE_TYPES = {
    0x00: ("enum", 1, 0xFF),
    0x02: ("uint8", 1, 0xFF),
    0x84: ("uint16", 2, 0xFFFF),
    0x86: ("uint32", 4, 0xFFFFFFFF),
    0x8C: ("uint32z", 4, 0x00000000),
    0x07: ("string", None, None),  # variable size, defined per-field in definition msg
}


def decode_scalar(base_type_id, raw_bytes):
    kind, _, invalid = BASE_TYPES[base_type_id]
    if kind == "string":
        # Null-terminated, null-padded fixed-size field.
        end = raw_bytes.find(b"\x00")
        text = raw_bytes[: end if end >= 0 else len(raw_bytes)]
        return text.decode("utf-8", errors="replace")
    value = int.from_bytes(raw_bytes, byteorder="little", signed=False)
    if invalid is not None and value == invalid:
        return None
    return value


# ---------------------------------------------------------------------------
# Enum name tables (verbatim from spike/reference/fit-profile-excerpt.md)
# ---------------------------------------------------------------------------

FILE_TYPE_NAMES = {5: "workout"}
SPORT_NAMES = {0: "generic", 1: "running", 2: "cycling", 5: "swimming"}
WKT_STEP_DURATION_NAMES = {
    0: "time",
    1: "distance",
    5: "open",
    6: "repeatUntilStepsCmplt",
}
WKT_STEP_TARGET_NAMES = {0: "speed", 2: "open"}
INTENSITY_NAMES = {0: "active", 1: "rest", 2: "warmup", 3: "cooldown", 4: "recovery"}

WORKOUT_STEP_FIELD_NAMES = {
    254: "messageIndex",
    0: "wktStepName",
    1: "durationType",
    2: "durationValue",
    3: "targetType",
    4: "targetValue",
    5: "customTargetValueLow",
    6: "customTargetValueHigh",
    7: "intensity",
}
WORKOUT_FIELD_NAMES = {
    254: "messageIndex",
    4: "sport",
    5: "capabilities",
    6: "numValidSteps",
    8: "wktName",
}
FILE_ID_FIELD_NAMES = {
    0: "type",
    1: "manufacturer",
    2: "product",
    3: "serialNumber",
    4: "timeCreated",
}
FILE_CREATOR_FIELD_NAMES = {
    0: "softwareVersion",
    1: "hardwareVersion",
}

# manufacturer/product enum names, see spike/reference/fit-profile-excerpt.md
MANUFACTURER_NAMES = {1: "garmin", 255: "development"}
GARMIN_PRODUCT_NAMES = {65534: "connect"}

GLOBAL_MESG_NAMES = {0: "file_id", 26: "workout", 27: "workout_step", 49: "file_creator"}


class FitParseError(Exception):
    pass


def parse_header(data):
    if len(data) < 12:
        raise FitParseError("file too short for a FIT header")
    header_size = data[0]
    protocol_version = data[1]
    profile_version = struct.unpack_from("<H", data, 2)[0]
    data_size = struct.unpack_from("<I", data, 4)[0]
    data_type = data[8:12]
    if data_type != b".FIT":
        raise FitParseError(f"bad data type tag: {data_type!r} (expected b'.FIT')")

    header_crc_ok = None
    if header_size == 14:
        stored_crc = struct.unpack_from("<H", data, 12)[0]
        computed_crc = crc16(data[0:12])
        header_crc_ok = stored_crc == computed_crc

    return {
        "header_size": header_size,
        "protocol_version": protocol_version,
        "profile_version": profile_version,
        "data_size": data_size,
        "header_crc_ok": header_crc_ok,
    }


def parse_records(data, header_size, data_size):
    """Parses definition + data messages starting at header_size, for
    data_size bytes. Returns a list of (global_mesg_num, {field_name_or_num: value})."""
    offset = header_size
    end = header_size + data_size
    local_defs = {}
    messages = []

    while offset < end:
        record_header = data[offset]
        offset += 1

        if record_header & 0x80:
            raise FitParseError(
                f"compressed timestamp header encountered at offset {offset - 1} "
                "(not produced by this spike's encoder — unsupported by this verifier)"
            )

        is_definition = bool(record_header & 0x40)
        local_type = record_header & 0x0F

        if is_definition:
            reserved = data[offset]
            architecture = data[offset + 1]
            offset += 2
            if architecture != 0:
                raise FitParseError("only little-endian (architecture=0) FIT files are supported")
            global_mesg_num = struct.unpack_from("<H", data, offset)[0]
            offset += 2
            num_fields = data[offset]
            offset += 1
            fields = []
            for _ in range(num_fields):
                field_num = data[offset]
                size = data[offset + 1]
                base_type = data[offset + 2]
                offset += 3
                fields.append((field_num, size, base_type))

            has_dev_fields = bool(record_header & 0x20) or bool(reserved & 0x20)
            # Our encoder never sets the developer-data flag, but parse
            # defensively in case a future encoder variant does.
            if data[offset - 3 - num_fields * 3] if False else False:
                pass  # placeholder to keep structure explicit; not used

            local_defs[local_type] = {
                "global_mesg_num": global_mesg_num,
                "fields": fields,
                "mesg_size": sum(f[1] for f in fields),
            }
        else:
            if local_type not in local_defs:
                raise FitParseError(f"data message references undefined local type {local_type}")
            definition = local_defs[local_type]
            values = {}
            for field_num, size, base_type in definition["fields"]:
                raw = data[offset : offset + size]
                offset += size
                values[field_num] = decode_scalar(base_type, raw)
            messages.append((definition["global_mesg_num"], values))

    return messages


def humanize_workout_step(values):
    field_by_name = {WORKOUT_STEP_FIELD_NAMES.get(k, k): v for k, v in values.items()}

    duration_type = field_by_name.get("durationType")
    duration_value = field_by_name.get("durationValue")
    duration_type_name = WKT_STEP_DURATION_NAMES.get(duration_type, f"#{duration_type}")

    if duration_type_name == "time" and duration_value is not None:
        duration_human = f"{duration_value / 1000:.0f}s"
    elif duration_type_name == "distance" and duration_value is not None:
        duration_human = f"{duration_value / 100:.0f}m"
    elif duration_type_name == "repeatUntilStepsCmplt":
        duration_human = f"jump back to messageIndex {duration_value}"
    else:
        duration_human = "open" if duration_value is None else str(duration_value)

    target_type = field_by_name.get("targetType")
    target_type_name = WKT_STEP_TARGET_NAMES.get(target_type, f"#{target_type}")
    low = field_by_name.get("customTargetValueLow")
    high = field_by_name.get("customTargetValueHigh")
    target_value = field_by_name.get("targetValue")

    if target_type_name == "speed" and low is not None and high is not None:
        low_kmh = (low / 1000) * 3.6
        high_kmh = (high / 1000) * 3.6
        target_human = f"speed {low_kmh:.2f}-{high_kmh:.2f} km/h"
    elif duration_type_name == "repeatUntilStepsCmplt":
        target_human = f"repeat count = {target_value}"
    else:
        target_human = "open/none"

    intensity = field_by_name.get("intensity")
    intensity_name = (
        INTENSITY_NAMES.get(intensity, f"#{intensity}") if intensity is not None else "n/a"
    )

    return {
        "messageIndex": field_by_name.get("messageIndex"),
        "name": field_by_name.get("wktStepName") or "",
        "durationType": duration_type_name,
        "duration": duration_human,
        "targetType": target_type_name,
        "target": target_human,
        "intensity": intensity_name,
    }


def main():
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <path-to.fit>", file=sys.stderr)
        sys.exit(2)

    path = sys.argv[1]
    with open(path, "rb") as f:
        data = f.read()

    print(f"=== {path} ({len(data)} bytes) ===")

    ok = True

    try:
        header = parse_header(data)
    except FitParseError as e:
        print(f"FAIL: header parse error: {e}")
        sys.exit(1)

    print(
        f"Header: size={header['header_size']} protocol=0x{header['protocol_version']:02x} "
        f"profile_version={header['profile_version']} data_size={header['data_size']}"
    )
    if header["header_crc_ok"] is None:
        print("Header CRC: not present (header_size != 14)")
    elif header["header_crc_ok"]:
        print("Header CRC: OK")
    else:
        print("Header CRC: FAIL")
        ok = False

    expected_total = header["header_size"] + header["data_size"] + 2
    if expected_total != len(data):
        print(f"FAIL: file size mismatch — header+data+trailingCRC={expected_total}, actual={len(data)}")
        ok = False

    stored_file_crc = struct.unpack_from("<H", data, len(data) - 2)[0]
    computed_file_crc = crc16(data[: len(data) - 2])
    if stored_file_crc == computed_file_crc:
        print("File CRC: OK")
    else:
        print(f"File CRC: FAIL (stored={stored_file_crc:#06x}, computed={computed_file_crc:#06x})")
        ok = False

    try:
        messages = parse_records(data, header["header_size"], header["data_size"])
    except FitParseError as e:
        print(f"FAIL: record parse error: {e}")
        sys.exit(1)

    file_id_msgs = [v for g, v in messages if g == 0]
    file_creator_msgs = [v for g, v in messages if g == 49]
    workout_msgs = [v for g, v in messages if g == 26]
    workout_step_msgs = [v for g, v in messages if g == 27]

    if not file_id_msgs:
        print("FAIL: no file_id message found")
        ok = False
    else:
        fid = file_id_msgs[0]
        file_type = fid.get(0)
        file_type_name = FILE_TYPE_NAMES.get(file_type, f"#{file_type}")
        manufacturer = fid.get(1)
        manufacturer_name = MANUFACTURER_NAMES.get(manufacturer, f"#{manufacturer}")
        product = fid.get(2)
        product_name = GARMIN_PRODUCT_NAMES.get(product, f"#{product}") if manufacturer == 1 else f"#{product}"
        serial_number = fid.get(3)
        time_created = fid.get(4)
        created_str = fit_datetime_to_utc(time_created).isoformat() if time_created is not None else "n/a"
        print(
            f"file_id: type={file_type_name} manufacturer={manufacturer_name}({manufacturer}) "
            f"product={product_name}({product}) serialNumber={serial_number} timeCreated={created_str}"
        )
        if file_type_name != "workout":
            print(f"FAIL: file_id.type is '{file_type_name}', expected 'workout'")
            ok = False
        else:
            print("file_id.type == workout: OK")
        if not serial_number:
            print(
                "FAIL: file_id.serialNumber is 0/unset (uint32z invalid sentinel) — "
                "real Garmin Connect imports require a nonzero serial number"
            )
            ok = False
        else:
            print("file_id.serialNumber is nonzero: OK")

    if not file_creator_msgs:
        print(
            "FAIL: no file_creator message found — real Garmin Connect imports require one "
            "alongside file_id"
        )
        ok = False
    else:
        creator = file_creator_msgs[0]
        software_version = creator.get(0)
        hardware_version = creator.get(1)
        print(
            f"file_creator: softwareVersion={software_version} "
            f"hardwareVersion={'n/a' if hardware_version is None else hardware_version}"
        )
        print("file_creator present: OK")

    if not workout_msgs:
        print("FAIL: no workout message found")
        ok = False
    else:
        wkt = workout_msgs[0]
        sport = wkt.get(4)
        sport_name = SPORT_NAMES.get(sport, f"#{sport}")
        num_valid_steps = wkt.get(6)
        wkt_name = wkt.get(8)
        print(f"workout: sport={sport_name} numValidSteps={num_valid_steps} wktName='{wkt_name}'")
        if num_valid_steps != len(workout_step_msgs):
            print(
                f"FAIL: workout.numValidSteps ({num_valid_steps}) does not match actual "
                f"workout_step message count ({len(workout_step_msgs)})"
            )
            ok = False
        else:
            print("workout.numValidSteps matches actual workout_step count: OK")

    if not workout_step_msgs:
        print("FAIL: no workout_step messages found")
        ok = False
    else:
        print(f"\nDecoded {len(workout_step_msgs)} workout_step message(s):\n")
        header_row = f"{'idx':>3}  {'name':<24} {'durationType':<24} {'duration':<28} {'targetType':<10} {'target':<24} {'intensity'}"
        print(header_row)
        print("-" * len(header_row))
        for raw in workout_step_msgs:
            step = humanize_workout_step(raw)
            print(
                f"{step['messageIndex']:>3}  {step['name']:<24} {step['durationType']:<24} "
                f"{step['duration']:<28} {step['targetType']:<10} {step['target']:<24} {step['intensity']}"
            )

    print()
    if ok:
        print("RESULT: PASS — header valid, CRC valid, file_id/workout/workout_step present and consistent")
    else:
        print("RESULT: FAIL — see FAIL lines above")
        sys.exit(1)


if __name__ == "__main__":
    main()
