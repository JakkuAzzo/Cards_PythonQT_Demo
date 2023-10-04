import sys
from PyQt6.QtWidgets import QApplication, QWidget, QLabel

# Function to read game config from file
def read_game_config(file_path):
    with open(file_path, 'r') as file:
        config_lines = file.readlines()
    
    config = {}
    for line in config_lines:
        key, value = line.strip().split(': ')
        config[key] = value
    
    return config

# Function to generate GUI based on game config
def generate_game_gui(config):
    app = QApplication(sys.argv)

    # Create a main window
    main_window = QWidget()
    main_window.setWindowTitle('Card Game')
    main_window.setGeometry(100, 100, 800, 600)

    # Create labels to display the game configuration
    for idx, (key, value) in enumerate(config.items()):
        label = QLabel(f'{key}: {value}', main_window)
        label.move(10, 10 + (idx * 20))

    main_window.show()
    sys.exit(app.exec())

# Read game config from file
config = read_game_config('game_config.txt')

# Generate and display the GUI
generate_game_gui(config)
