import os
import re
from datetime import datetime

# Valoqui Doc Linker - Automated Indexer & Auditor
# This script ensures that when a decision changes, the impact is propagated.

ADR_DIR = "docs/decisions"
ADR_README = os.path.join(ADR_DIR, "README.md")
ARCH_FILE = "docs/ARCHITECTURE.md"
CHANGELOG = "CHANGELOG.md"

def get_adrs():
    adrs = []
    adr_files = sorted([f for f in os.listdir(ADR_DIR) if f.startswith("ADR-") and f.endswith(".md") and f != "ADR-000-template.md"])
    
    for filename in adr_files:
        path = os.path.join(ADR_DIR, filename)
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            # Extract ID and Title
            title_match = re.search(r"^#\s+(ADR-\d+):\s*(.*)", content, re.MULTILINE)
            if title_match:
                adr_id = title_match.group(1)
                title = title_match.group(2).strip()
            else:
                adr_id = "-".join(filename.split("-")[:2])
                title = filename.replace(".md", "").replace("-", " ").title()
            
            # Extract status
            status_match = re.search(r"\*\*Status:\*\*\s*(.*)", content)
            status = status_match.group(1).strip() if status_match else "Unknown"
            
            # Extract Date for Changelog/Audit
            date_match = re.search(r"\*\*Date:\*\*\s*(.*)", content)
            date = date_match.group(1).strip() if date_match else datetime.now().strftime("%Y-%m-%d")

            # Extract Summary (look for ## Summary section)
            summary_match = re.search(r"## Summary\s*\n(.*?)(?=\n##|\n---|$)", content, re.DOTALL)
            summary = summary_match.group(1).strip() if summary_match else "No summary provided."

            adrs.append({
                "id": adr_id,
                "filename": filename,
                "title": title,
                "status": status,
                "date": date,
                "summary": summary,
                "content": content
            })
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
    index_section_pattern = r"(## Index\s*)\n(\| ADR \| Title \| Status \|\n\| ----- \| ------- \| -------- \|\n(?:\| .* \|\n)*(\n)*)*"
    updated_content = re.sub(index_section_pattern, f"## Index\n\n{new_table}\n", content, flags=re.MULTILINE)

    with open(ADR_README, "w", encoding="utf-8") as f:
        f.write(updated_content)
    print(f"✅ Updated Index: {ADR_README}")

def update_architecture_md(adrs):
    if not os.path.exists(ARCH_FILE): return
    with open(ARCH_FILE, "r", encoding="utf-8") as f:
        content = f.read()
    
    for adr in adrs:
        # Update mentions: **Title (ADR-XXX)**
        pattern = rf"\*\*(.*) \({adr['id']}\)\*\*"
        replacement = f"**{adr['title']} ({adr['id']})**"
        content = re.sub(pattern, replacement, content)
        
        # Look for existing bullet point descriptions of these ADRs to update them too
        # Pattern: - **Title (ADR-XXX):** {Old Description}
        pattern_desc = rf"- \*\*{adr['title']} \({adr['id']}\):\*\* (.*)"
        replacement_desc = f"- **{adr['title']} ({adr['id']}):** {adr['summary']}"
        content = re.sub(pattern_desc, replacement_desc, content)
    
    with open(ARCH_FILE, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✅ Updated References: {ARCH_FILE}")

def audit_changelog(adrs):
    """Checks if the latest ADR changes are reflected in CHANGELOG.md"""
    if not os.path.exists(CHANGELOG): return
    
    with open(CHANGELOG, "r", encoding="utf-8") as f:
        log_content = f.read()
    
    # We look for the most recently modified ADR (by date in file)
    latest_adr = max(adrs, key=lambda x: x['date'])
    
    if latest_adr['id'] not in log_content:
        print(f"🚨 AUDIT FAILURE: {latest_adr['id']} ('{latest_adr['title']}') is not mentioned in {CHANGELOG}")
        print(f"👉 ACTION REQUIRED: Add a summary of this decision to the [Unreleased] or current version section.")
        print(f"Suggested Entry: - [{latest_adr['id']}] {latest_adr['title']}: {latest_adr['summary']}")
    else:
        print(f"✨ Audit Passed: {latest_adr['id']} found in {CHANGELOG}")

if __name__ == "__main__":
    adrs = get_adrs()
    update_adr_readme(adrs)
    update_architecture_md(adrs)
    audit_changelog(adrs)
