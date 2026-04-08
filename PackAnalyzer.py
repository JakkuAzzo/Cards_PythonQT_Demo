from pathlib import Path


class PackAnalyzer:
    def analyze(self, pack_path):
        pack_dir = Path(pack_path)
        if not pack_dir.exists() or not pack_dir.is_dir():
            return {
                "pack_name": pack_dir.name or str(pack_path),
                "pack_path": str(pack_dir),
                "entry_script": None,
                "config_path": None,
                "config": {},
            }

        config_path = pack_dir / "game_config.txt"
        config = {}
        if config_path.exists():
            with config_path.open("r") as file:
                for raw_line in file:
                    line = raw_line.strip()
                    if not line or ": " not in line:
                        continue
                    key, value = line.split(": ", 1)
                    config[key] = value

        entry_script = None
        for candidate in sorted(pack_dir.glob("*.py")):
            if candidate.name != "__init__.py":
                entry_script = str(candidate)
                break

        return {
            "pack_name": pack_dir.name,
            "pack_path": str(pack_dir),
            "entry_script": entry_script,
            "config_path": str(config_path) if config_path.exists() else None,
            "config": config,
        }
