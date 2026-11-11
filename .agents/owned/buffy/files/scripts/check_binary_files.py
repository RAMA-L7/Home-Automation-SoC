import sys
import os
sys.path.insert(0, r"C:\Users\91846\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\Lib\site-packages")

from docx import Document

files = [
    r"D:\Home-Automation-SoC\docs\architecture\BUS_AND_MEMORY_ARCHITECTURE.md",
    r"D:\Home-Automation-SoC\docs\architecture\SECURITY_ARCHITECTURE.md",
    r"D:\Home-Automation-SoC\docs\architecture\BOOT_AND_FIRMWARE_ARCHITECTURE.md"
]

for f in files:
    if os.path.exists(f):
        try:
            doc = Document(f)
            print(f"=== {f} ===")
            for para in doc.paragraphs:
                if para.text.strip():
                    print(para.text)
            for table in doc.tables:
                print("--- TABLE ---")
                for row in table.rows:
                    print(" | ".join(cell.text for cell in row.cells))
            print()
        except Exception as e:
            print(f"{f}: ERROR - {e}")
            with open(f, 'rb') as fp:
                header = fp.read(64)
            print(f"  Header: {header.hex()}")
            print()
    else:
        print(f"{f}: NOT FOUND")