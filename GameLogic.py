import sys
import os
import importlib.util
from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QFrame, QScrollArea


class GameLogic(QWidget):
    def __init__(self, pack_metadata=None):
        super().__init__()
        self.pack_metadata = pack_metadata or {}
        self.game_widget = None
        self.initUI()

    def initUI(self):
        """Initialize UI, attempting to load the game widget from the entry script."""
        layout = QVBoxLayout()
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)

        # Try to load the game widget from the entry script
        game_widget = self._load_game_widget()
        
        if game_widget is not None:
            # Successfully loaded the game widget; display it
            self.game_widget = game_widget
            layout.addWidget(self.game_widget)
        else:
            # Fall back to preview mode
            layout.addLayout(self._create_preview_layout())

        self.setLayout(layout)

    def _load_game_widget(self):
        """
        Attempt to import and execute the entry script to get a game widget.
        Returns the widget on success, None on failure.
        """
        entry_script = self.pack_metadata.get("entry_script")
        pack_path = self.pack_metadata.get("pack_path")
        config = self.pack_metadata.get("config", {})

        if not entry_script or not os.path.exists(entry_script):
            return None

        try:
            # Load the module from the entry script file
            spec = importlib.util.spec_from_file_location("entry_module", entry_script)
            module = importlib.util.module_from_spec(spec)
            
            # Change to pack directory so relative imports/file paths work
            original_cwd = os.getcwd()
            os.chdir(pack_path)
            
            try:
                spec.loader.exec_module(module)
            finally:
                os.chdir(original_cwd)

            # Try to call create_game_widget if it exists
            if hasattr(module, 'create_game_widget'):
                return module.create_game_widget(config)
            
            return None
        except Exception as e:
            print(f"Error loading game widget from {entry_script}: {e}")
            import traceback
            traceback.print_exc()
            return None

    def _create_preview_layout(self):
        """Create the metadata preview layout (fallback if game widget not available)."""
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(10)

        title = QLabel(self.pack_metadata.get("pack_name", "Loaded Pack"))
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setStyleSheet("font-weight: bold; font-size: 16px;")

        subtitle = QLabel("Pack preview (game widget not available)")
        subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        subtitle.setStyleSheet("color: gray; font-size: 12px;")

        summary = QFrame()
        summary_layout = QVBoxLayout()
        summary_layout.setContentsMargins(12, 12, 12, 12)
        summary_layout.setSpacing(6)

        entry_script = self.pack_metadata.get("entry_script") or "No Python entry script detected"
        config_path = self.pack_metadata.get("config_path") or "No game_config.txt found"

        summary_layout.addWidget(QLabel(f"Entry script: {entry_script}"))
        summary_layout.addWidget(QLabel(f"Config file: {config_path}"))

        config = self.pack_metadata.get("config", {})
        if config:
            summary_layout.addWidget(QLabel("Config values:"))
            for key, value in config.items():
                summary_layout.addWidget(QLabel(f"{key}: {value}"))
        else:
            summary_layout.addWidget(QLabel("This pack has no readable config values yet."))

        summary.setLayout(summary_layout)

        layout.addWidget(title)
        layout.addWidget(subtitle)
        layout.addWidget(summary)
        return layout
