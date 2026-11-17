import json
import sys

def get_max_id(items, key="id"):
    return max((item.get(key, 0) for item in items if isinstance(item.get(key), int)), default=0)

def get_max_param(controls):
    max_p = 0
    for c in controls:
        for v in c.get("values", []):
            p = v.get("message", {}).get("parameterNumber")
            if isinstance(p, int) and p > max_p:
                max_p = p
    return max_p

def merge_electra_presets(file_paths, output_path, new_name="Korg Z1 Complete"):
    if not file_paths:
        print("No input files provided.")
        return

    first_file = file_paths.pop(0)
    with open(first_file, "r", encoding="utf-8") as f:
        merged = json.load(f)

    merged["name"] = new_name
    for key in ("pages", "groups", "controls", "overlays"):
        merged.setdefault(key, [])

    max_page_id = get_max_id(merged["pages"])
    max_group_id = get_max_id(merged["groups"])
    max_ctrl_id = get_max_id(merged["controls"])
    max_ovl_id = get_max_id(merged["overlays"])
    max_param_num = get_max_param(merged["controls"])

    for path in file_paths:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)

        page_map = {}
        group_map = {}
        ovl_map = {}
        param_map = {}

        # 1. Offset Pages
        for p in data.get("pages", []):
            old_id = p["id"]
            max_page_id += 1
            p["id"] = max_page_id
            page_map[old_id] = max_page_id
            merged["pages"].append(p)

        # 2. Offset Overlays
        for o in data.get("overlays", []):
            old_id = o["id"]
            max_ovl_id += 1
            o["id"] = max_ovl_id
            ovl_map[old_id] = max_ovl_id
            merged["overlays"].append(o)

        # 3. Offset Groups
        for g in data.get("groups", []):
            old_id = g["id"]
            max_group_id += 1
            g["id"] = max_group_id
            if g.get("pageId") in page_map:
                g["pageId"] = page_map[g["pageId"]]
            group_map[old_id] = max_group_id
            merged["groups"].append(g)

        # 4. Offset Controls, nested overlayIds, and virtual parameterNumbers
        for c in data.get("controls", []):
            max_ctrl_id += 1
            c["id"] = max_ctrl_id

            if c.get("pageId") in page_map:
                c["pageId"] = page_map[c["pageId"]]
            if c.get("groupId") in group_map:
                c["groupId"] = group_map[c["groupId"]]

            for v in c.get("values", []):
                if v.get("overlayId") in ovl_map:
                    v["overlayId"] = ovl_map[v["overlayId"]]

                msg = v.get("message", {})
                if msg.get("type") == "virtual" and isinstance(msg.get("parameterNumber"), int):
                    old_p = msg["parameterNumber"]
                    if old_p not in param_map:
                        max_param_num += 1
                        param_map[old_p] = max_param_num
                    msg["parameterNumber"] = param_map[old_p]

            merged["controls"].append(c)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, indent=2)

    print(f"Done! Wrote {output_path}: {len(merged['pages'])} pages, {len(merged['controls'])} controls, max virtual param={max_param_num}")

if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) < 2:
        print("Usage: python3 merge_presets.py <output.json> <input1.json> <input2.json> ...")
        sys.exit(1)
    out_file = args.pop(0)
    merge_electra_presets(args, out_file)

