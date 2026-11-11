@echo off
echo "=== Staging all changes ==="
git add -A
echo "=== Committing ==="
git commit -F COMMIT_MSG.txt
echo "=== Adding remote ==="
git remote add origin https://github.com/RAMA-L7/Home-Automation-SoC.git 2>nul
echo "=== Pushing to main ==="
git branch -M main
git push -u origin main
echo "=== Creating tag ==="
git tag v0.2.0-rtl-fixes -m "RTL deadlock fixes: load/store address + boot_rom handshake"
git push origin v0.2.0-rtl-fixes
echo "=== Done ==="
