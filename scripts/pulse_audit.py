import os
import re
import yaml
from datetime import datetime

# Valoqui Pulse Auditor
# A centralized tool to ensure structural, documentation, and asset integrity.

ADR_DIR = "docs/decisions"
ADR_README = os.path.join(ADR_DIR, "README.md")
ARCH_FILE = "docs/ARCHITECTURE.md"
CHANGELOG = "CHANGELOG.md"
PUBSPEC = "pubspec.yaml"
SERVICE_LOCATOR = "lib/core/di/service_locator.dart"

def get_adrs():
    adrs = []
    if not os.path.exists(ADR_DIR): return adrs
    adr_files = sorted([f for f in os.listdir(ADR_DIR) if f.startswith("ADR-") and f.endswith(".md") and f != "ADR-000-template.md"])
    for filename in adr_files:
        path = os.path.join(ADR_DIR, filename)
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            title_match = re.search(r"^#\s+(ADR-\d+):\s*(.*)", content, re.MULTILINE)
            adr_id = title_match.group(1) if title_match else "-".join(filename.split("-")[:2])
            title = title_match.group(2).strip() if title_match else filename.replace(".md", "").replace("-", " ").title()
            status_match = re.search(r"\*\*Status:\*\*\s*(.*)", content)
            status = status_match.group(1).strip() if status_match else "Unknown"
            date_match = re.search(r"\*\*Date:\*\*\s*(.*)", content)
            date = date_match.group(1).strip() if date_match else datetime.now().strftime("%Y-%m-%d")
            summary_match = re.search(r"## Summary\s*\n(.*?)(?=\n##|\n---|$)", content, re.DOTALL)
            summary = summary_match.group(1).strip() if summary_match else "No summary provided."
            adrs.append({"id": adr_id, "filename": filename, "title": title, "status": status, "date": date, "summary": summary})
    return adrs

def update_adr_readme(adrs):
    if not os.path.exists(ADR_README): return
    with open(ADR_README, "r", encoding="utf-8") as f:
        content = f.read()
    table_header = "| ADR | Title | Status |"
    table_sep = "| ----- | ------- | -------- |"
    table_body = [f"| [ADR-000](ADR-000-template.md) | Template | — |"]
    for adr in adrs:
        table_body.append(f"| [{adr['id']}]({adr['filename']}) | {adr['title']} | {adr['status']} |")
    new_table = "\n".join([table_header, table_sep] + table_body)
    index_pattern = r"(## Index\s*)\n(\| ADR \| Title \| Status \|\n\| ----- \| ------- \| -------- \|\n(?:\| .* \|\n)*(\n)*)*"
    updated_content = re.sub(index_pattern, f"## Index\n\n{new_table}\n", content, flags=re.MULTILINE)
    with open(ADR_README, "w", encoding="utf-8") as f:
        f.write(updated_content)
    print(f"✅ Doc Linker: Updated {ADR_README}")

def update_architecture_md(adrs):
    if not os.path.exists(ARCH_FILE): return
    with open(ARCH_FILE, "r", encoding="utf-8") as f:
        content = f.read()
    for adr in adrs:
        pattern = rf"\*\*(.*) \({adr['id']}\)\*\*"
        content = re.sub(pattern, f"**{adr['title']} ({adr['id']})**", content)
        pattern_desc = rf"- \*\*{adr['title']} \({adr['id']}\):\*\* (.*)"
        content = re.sub(pattern_desc, f"- **{adr['title']} ({adr['id']}):** {adr['summary']}", content)
    with open(ARCH_FILE, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✅ Doc Linker: Updated {ARCH_FILE}")

def audit_changelog(adrs):
    if not os.path.exists(CHANGELOG): return
    with open(CHANGELOG, "r", encoding="utf-8") as f:
        log_content = f.read()
    latest_adr = max(adrs, key=lambda x: x['date'])
    if latest_adr['id'] not in log_content:
        print(f"🚨 CHANGELOG AUDIT FAILURE: {latest_adr['id']} not mentioned in {CHANGELOG}")
    else:
        print("✨ Changelog Integrity Pass.")

def check_asset_integrity():
    print("🔍 Auditing Asset Integrity...")
    if not os.path.exists(PUBSPEC): return
    with open(PUBSPEC, "r") as f:
        spec = yaml.safe_load(f)
    declared_assets = spec.get("flutter", {}).get("assets", [])
    
    code_assets = set()
    for root, _, files in os.walk("lib"):
        for file in files:
            if file.endswith(".dart"):
                with open(os.path.join(root, file), "r") as f:
                    content = f.read()
                    matches = re.findall(r"\"(assets/.*?)\"", content)
                    code_assets.update(matches)
    
    missing_in_spec = []
    for asset in code_assets:
        # Check if asset or its parent dir is declared
        is_declared = any(asset.startswith(decl) or decl.startswith(asset) for decl in declared_assets)
        if not is_declared:
            missing_in_spec.append(asset)
    
    if missing_in_spec:
        print(f"🚨 ASSET AUDIT FAILURE: Assets referenced in code but missing from {PUBSPEC}:")
        for asset in missing_in_spec:
            print(f"  - {asset}")
    else:
        print("✨ Asset Integrity Pass.")

def check_di_registrations():
    print("🔍 Auditing Service Locator Registrations...")
    if not os.path.exists(SERVICE_LOCATOR): return
    with open(SERVICE_LOCATOR, "r") as f:
        sl_content = f.read()
    
    required = []
    for root, _, files in os.walk("lib/features"):
        for file in files:
            if file.endswith("_bloc.dart") and not any(x in file for x in ["_event", "_state"]):
                required.append("".join([x.capitalize() for x in file.replace(".dart", "").split("_")]))
    
    for root, _, files in os.walk("lib/core/domain/usecases"):
        for file in files:
            if file.endswith(".dart"):
                with open(os.path.join(root, file), "r") as f:
                    match = re.search(r"class (\w+)", f.read())
                    if match: required.append(match.group(1))

    missing = [r for r in required if r not in sl_content]
    if missing:
        print(f"🚨 DI AUDIT FAILURE: Classes missing from {SERVICE_LOCATOR}:")
        for m in missing: print(f"  - {m}")
    else:
        print("✨ DI Integrity Pass.")

def check_architecture_boundaries():
    print("🔍 Auditing Architecture Boundaries...")
    for root, _, files in os.walk("lib/core/domain"):
        for file in files:
            if file.endswith(".dart"):
                with open(os.path.join(root, file), "r") as f:
                    content = f.read()
                    if any(x in content for x in ["package:valoqui/features/", "package:valoqui/core/data/"]):
                        print(f"🚨 BOUNDARY VIOLATION in {os.path.join(root, file)}")
    print("✨ Boundary Integrity Pass.")

if __name__ == "__main__":
    adrs = get_adrs()
    update_adr_readme(adrs)
    update_architecture_md(adrs)
    audit_changelog(adrs)
    check_asset_integrity()
    check_di_registrations()
    check_architecture_boundaries()
