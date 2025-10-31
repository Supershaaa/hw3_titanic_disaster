# src/app/check_setup.py
import sys, pathlib

root = pathlib.Path(__file__).resolve().parents[2]
data_dir = root / "src" / "data"

print("✅ Environment OK")
print("Python:", sys.version)
print("Repo root:", root)
print("Data dir exists:", data_dir.exists())
print("CSV files in data:", [p.name for p in data_dir.glob("*.csv")])