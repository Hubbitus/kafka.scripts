#!/usr/bin/env python3
"""
Pretty-print JSON with adaptive formatting.

Inspired by FracturedJson (https://github.com/j-brooke/FracturedJson) — same
adaptive philosophy (inline what fits, expand what does not, table-align
homogeneous arrays). Extra features on top of fracjson:
  - JSONL / concatenated JSON documents supported (fracjson: single doc).
  - Default width = terminal width via shutil.get_terminal_size (fracjson: fixed).
  - --unpack-strings: recursively parse string values that themselves contain
    JSON (useful for Kafka payloads where the value is a JSON-encoded string).
  - Mixed object rendering: scalar keys packed multi-per-line, complex keys
    (nested objects/arrays) placed on their own lines. fracjson forces all-
    inline or all-expanded per object level.

Behaviour:
  - Objects/arrays inline if they fit in width.
  - Array of homogeneous objects → table with column-aligned keys and values,
    including nested inline dicts (inner keys aligned across rows).
  - Array of arrays with scalar items → table with right-aligned numeric
    columns, packed rows.
  - Otherwise expand recursively.

Usage: cat file.json | json-compact-format.py [--width N] [--indent N] [--unpack-strings]
"""
import json, sys, argparse, shutil

def unpack(v):
    if isinstance(v, str):
        s = v.strip()
        if s and s[0] in "{[":
            try:
                return unpack(json.loads(s))
            except (ValueError, TypeError):
                return v
        return v
    if isinstance(v, dict):
        return {k: unpack(x) for k, x in v.items()}
    if isinstance(v, list):
        return [unpack(x) for x in v]
    return v

def is_scalar(v):
    return not isinstance(v, (dict, list))

def dumps(v):
    return json.dumps(v, ensure_ascii=False)

def is_flat_scalar_array(v):
    return isinstance(v, list) and all(is_scalar(x) for x in v)

def is_homogeneous_objects(arr):
    if not arr or not all(isinstance(x, dict) for x in arr):
        return False
    all_scalar = all(all(is_scalar(v) for v in o.values()) or all(is_scalar_or_flat(v) for v in o.values()) for o in arr)
    return all_scalar

def is_scalar_or_flat(v):
    if is_scalar(v):
        return True
    if isinstance(v, dict):
        return all(is_scalar(x) for x in v.values())
    if isinstance(v, list):
        return all(is_scalar(x) for x in v)
    return False

def is_array_of_flat_arrays(arr):
    return arr and all(isinstance(x, list) and all(is_scalar(y) for y in x) for x in arr)

def render_cell(v):
    if is_scalar(v):
        return dumps(v)
    if isinstance(v, dict):
        return "{" + ", ".join(f"{dumps(k)}: {render_cell(x)}" for k, x in v.items()) + "}"
    if isinstance(v, list):
        return "[" + ", ".join(render_cell(x) for x in v) + "]"

def render_dict_column(raw_values):
    """raw_values: list of dicts (or None). Render each as inline dict with inner values padded per inner key."""
    present = [v for v in raw_values if isinstance(v, dict)]
    inner_keys = []
    for d in present:
        for k in d:
            if k not in inner_keys:
                inner_keys.append(k)
    inner_cols = {k: [] for k in inner_keys}
    for d in present:
        for k in inner_keys:
            inner_cols[k].append(dumps(d[k]) if k in d else None)
    inner_widths = {}
    inner_nums = {}
    for k in inner_keys:
        subs = [x for x in inner_cols[k] if x is not None]
        inner_widths[k] = max((len(x) for x in subs), default=0)
        inner_nums[k] = subs and all(x.lstrip("-").replace(".", "", 1).isdigit() for x in subs)
    out = []
    for v in raw_values:
        if not isinstance(v, dict):
            out.append(None)
            continue
        last_present = -1
        for j, k in enumerate(inner_keys):
            if k in v:
                last_present = j
        parts = []
        for j, k in enumerate(inner_keys):
            w = inner_widths[k]
            sep = "" if j >= last_present else ", "
            if k in v:
                val = dumps(v[k])
                val = val.rjust(w) if inner_nums[k] else val.ljust(w)
                parts.append(f"{dumps(k)}: {val}" + sep)
            else:
                cell_w = len(dumps(k)) + 2 + w
                parts.append(" " * cell_w + " " * len(sep))
        out.append("{" + "".join(parts).rstrip() + "}")
    return out

def table_objects(arr, inner, width):
    keys = []
    for o in arr:
        for k in o:
            if k not in keys:
                keys.append(k)
    cols = {k: [] for k in keys}
    raw_cols = {k: [] for k in keys}
    for o in arr:
        for k in keys:
            raw_cols[k].append(o[k] if k in o else None)
    for k in keys:
        raws = raw_cols[k]
        if all(isinstance(x, dict) or x is None for x in raws) and any(isinstance(x, dict) for x in raws):
            cols[k] = render_dict_column(raws)
        else:
            cols[k] = [render_cell(x) if x is not None else None for x in raws]
    for k in keys:
        vals = cols[k]
        subs = [x for x in vals if x is not None]
        starts = [x for x in subs if not x.startswith("{") and not x.startswith("[")]
        w = max((len(x) for x in subs), default=0)
        num = all(x.lstrip("-").replace(".", "", 1).isdigit() for x in starts) and starts
        cols[k] = (vals, w, num)
    rows = []
    for i in range(len(arr)):
        last_present = max((j for j, k in enumerate(keys) if cols[k][0][i] is not None), default=-1)
        parts = []
        for j, k in enumerate(keys):
            vals, w, num = cols[k]
            v = vals[i]
            is_last_col = j == len(keys) - 1
            if v is None:
                width_cell = len(dumps(k)) + 2 + w
                sep_len = 0 if is_last_col else 2
                parts.append(" " * (width_cell + sep_len))
            else:
                sep = "" if j >= last_present else ","
                cell_core = f"{dumps(k)}: {v}{sep}"
                if num:
                    key_prefix = f"{dumps(k)}: "
                    val_padded = v.rjust(w)
                    cell = f"{key_prefix}{val_padded}{sep}"
                else:
                    cell = cell_core
                target_len = len(dumps(k)) + 2 + w + (0 if is_last_col else 2)
                cell = cell.ljust(target_len)
                parts.append(cell)
        row = "{ " + "".join(parts).rstrip() + " }"
        rows.append(inner + row)
    max_row = max(len(r) for r in rows)
    rows = [r[:-2] + " " * (max_row - len(r)) + " }" for r in rows]
    return "[\n" + ",\n".join(rows) + "\n" + inner[:-4] + "]"

def table_arrays(arr, inner, width):
    ncols = max(len(x) for x in arr)
    cols = [[] for _ in range(ncols)]
    for row in arr:
        for i in range(ncols):
            cols[i].append(dumps(row[i]) if i < len(row) else "")
    widths = [max(len(c) for c in col) for col in cols]
    nums = [all(c == "" or c.lstrip("-").replace(".", "", 1).isdigit() for c in col) for col in cols]
    items = []
    for row in arr:
        parts = []
        for i in range(ncols):
            v = dumps(row[i]) if i < len(row) else ""
            parts.append(v.rjust(widths[i]) if nums[i] else v.ljust(widths[i]))
        items.append("[" + ", ".join(parts) + "]")
    item_w = max(len(x) for x in items)
    rows, cur, cur_len = [], [], 0
    avail = width - len(inner)
    for it in items:
        add = len(it) + (2 if cur else 0)
        if cur and cur_len + add > avail:
            rows.append(", ".join(cur))
            cur, cur_len = [it], len(it)
        else:
            cur.append(it)
            cur_len += add
    if cur:
        rows.append(", ".join(cur))
    body = ",\n".join(inner + r for r in rows)
    return "[\n" + body + "\n" + inner[:-4] + "]"

def fmt(node, indent, width, level=0):
    pad = " " * (indent * level)
    inner = " " * (indent * (level + 1))

    if isinstance(node, dict):
        if not node:
            return "{}"
        inline = dumps(node)
        if len(pad) + len(inline) <= width:
            return inline
        key_w = max((len(dumps(k)) for k in node), default=0)
        # Special-case: dict whose values are all flat scalar arrays.
        # Render as table: keys aligned, inner arrays column-aligned.
        if node and all(is_flat_scalar_array(v) for v in node.values()):
            ncols = max(len(v) for v in node.values())
            cell_grid = []
            for k, v in node.items():
                row = [dumps(x) for x in v] + [""] * (ncols - len(v))
                cell_grid.append(row)
            col_w = [max(len(row[j]) for row in cell_grid) for j in range(ncols)]
            col_num = [all(row[j] == "" or row[j].lstrip("-").replace(".", "", 1).isdigit() for row in cell_grid) for j in range(ncols)]
            lines = []
            for (k, v), row in zip(node.items(), cell_grid):
                kj = dumps(k)
                kp = kj + " " * (key_w - len(kj))
                parts = []
                last_present = max((j for j, c in enumerate(row) if c != ""), default=-1)
                for j in range(ncols):
                    c = row[j]
                    is_last = j == ncols - 1
                    sep = "" if j >= last_present else ","
                    if c == "":
                        cell_w = col_w[j] + (0 if is_last else 2)
                        parts.append(" " * cell_w)
                    else:
                        target = col_w[j] + (0 if is_last else 2)
                        if col_num[j]:
                            pv = c.rjust(col_w[j])
                            parts.append(f"{pv}{sep}".ljust(target))
                        else:
                            parts.append(f"{c}{sep}".ljust(target))
                lines.append(f"{inner}{kp}: [{''.join(parts)}]")
            return "{\n" + ",\n".join(lines) + "\n" + pad + "}"

        # Split into groups: runs of scalar-value keys vs single non-scalar keys.
        groups = []
        cur_scalars = []
        for k, v in node.items():
            if is_scalar(v):
                cur_scalars.append((k, v))
            else:
                if cur_scalars:
                    groups.append(("scalars", cur_scalars))
                    cur_scalars = []
                groups.append(("complex", (k, v)))
        if cur_scalars:
            groups.append(("scalars", cur_scalars))

        lines = []
        avail = width - len(inner)
        for kind, payload in groups:
            if kind == "complex":
                k, v = payload
                sub = fmt(v, indent, width, level + 1)
                lines.append(f"{inner}{dumps(k)}: {sub}")
            else:
                items = [f"{dumps(k)}: {dumps(v)}" for k, v in payload]
                # Pack items into rows fitting width.
                rows, cur, cur_len = [], [], 0
                for it in items:
                    add = len(it) + (2 if cur else 0)
                    if cur and cur_len + add > avail:
                        rows.append(", ".join(cur))
                        cur, cur_len = [it], len(it)
                    else:
                        cur.append(it)
                        cur_len += add
                if cur:
                    rows.append(", ".join(cur))
                for r in rows:
                    lines.append(inner + r)
        return "{\n" + ",\n".join(lines) + "\n" + pad + "}"

    if isinstance(node, list):
        if not node:
            return "[]"
        inline = dumps(node)
        if len(pad) + len(inline) <= width and "\n" not in inline:
            return inline
        if is_homogeneous_objects(node):
            return table_objects(node, inner, width)
        if is_array_of_flat_arrays(node):
            return table_arrays(node, inner, width)
        items = [fmt(v, indent, width, level + 1) for v in node]
        if all("\n" not in it for it in items):
            item_w = max(len(it) for it in items)
            rows, cur, cur_len = [], [], 0
            avail = width - len(inner)
            for it in items:
                pit = it.rjust(item_w)
                add = len(pit) + (2 if cur else 0)
                if cur and cur_len + add > avail:
                    rows.append(", ".join(cur))
                    cur, cur_len = [pit], len(pit)
                else:
                    cur.append(pit)
                    cur_len += add
            if cur:
                rows.append(", ".join(cur))
            body = ",\n".join(inner + r for r in rows)
            return "[\n" + body + "\n" + pad + "]"
        lines = [inner + it for it in items]
        return "[\n" + ",\n".join(lines) + "\n" + pad + "]"

    return dumps(node)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--width", type=int, default=shutil.get_terminal_size((270, 24)).columns)
    ap.add_argument("--indent", type=int, default=2)
    ap.add_argument("--unpack-strings", action="store_true", help="Recursively parse string values that contain valid JSON")
    ap.add_argument("file", nargs="?")
    args = ap.parse_args()
    src = open(args.file) if args.file else sys.stdin
    text = src.read()
    dec = json.JSONDecoder()
    i, n = 0, len(text)
    while i < n:
        while i < n and text[i].isspace():
            i += 1
        if i >= n:
            break
        obj, end = dec.raw_decode(text, i)
        if args.unpack_strings:
            obj = unpack(obj)
        print(fmt(obj, args.indent, args.width))
        i = end

if __name__ == "__main__":
    main()
