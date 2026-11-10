import os

files = [
    r"D:\Home-Automation-SoC\docs\architecture\BUS_AND_MEMORY_ARCHITECTURE.md",
    r"D:\Home-Automation-SoC\docs\architecture\SECURITY_ARCHITECTURE.md",
    r"D:\Home-Automation-SoC\docs\architecture\BOOT_AND_FIRMWARE_ARCHITECTURE.md"
]

for f in files:
    if os.path.exists(f):
        size = os.path.getsize(f)
        with open(f, 'rb') as fp:
            header = fp.read(64)
        print(f"{f}: size={size}")
        print(f"  Header: {header.hex()}")
        # Check for common file signatures
        if header.startswith(b'PK\x03\x04'):
            print("  -> ZIP/DOCX format detected")
        elif header.startswith(b'%PDF'):
            print("  -> PDF format detected")
        elif header.startswith(b'\xFF\xFE') or header.startswith(b'\xFE\xFF'):
            print("  -> UTF-16 BOM detected")
        elif header.startswith(b'\xEF\xBB\xBF'):
            print("  -> UTF-8 BOM detected")
        else:
            print("  -> Unknown format")
        print()
    else:
        print(f"{f}: NOT FOUND")
        print()