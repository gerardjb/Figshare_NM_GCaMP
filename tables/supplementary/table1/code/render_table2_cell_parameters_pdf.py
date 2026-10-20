"""Render SupplementaryTable1 from its publication data using ReportLab."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "tools"))
from render_tables import main

if __name__ == "__main__":
    main(default_item="SupplementaryTable1")
