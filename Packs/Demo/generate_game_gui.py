import sys
import os
from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QApplication, QWidget, QLabel, QVBoxLayout, QHBoxLayout, QGridLayout, QPushButton, QFrame
from PyQt6.QtGui import QColor

# Function to read game config from file
def read_game_config(file_path):
    with open(file_path, 'r') as file:
        config_lines = file.readlines()
    
    config = {}
    for line in config_lines:
        key, value = line.strip().split(': ')
        config[key] = value
    
    return config

# Function to create a card widget
def create_card_widget(suit, rank):
    """Create a simple card visual."""
    card = QFrame()
    card.setStyleSheet("""
        QFrame {
            background-color: white;
            border: 2px solid #333;
            border-radius: 8px;
        }
    """)
    card.setFixedSize(80, 120)
    
    layout = QVBoxLayout()
    layout.setContentsMargins(5, 5, 5, 5)
    layout.setSpacing(0)
    
    rank_label = QLabel(rank)
    rank_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
    rank_label.setStyleSheet("font-weight: bold; font-size: 18px;")
    
    suit_label = QLabel(suit)
    suit_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
    suit_label.setStyleSheet(f"font-size: 24px; color: {'red' if suit in '♥♦' else 'black'};")
    
    layout.addWidget(rank_label)
    layout.addStretch()
    layout.addWidget(suit_label)
    layout.addStretch()
    layout.addWidget(rank_label)
    
    card.setLayout(layout)
    return card

# Function to generate GUI widget based on game config (returns QWidget, does not start app)
def create_game_widget(config):
    """Create and return an interactive card game widget without starting a new event loop."""
    container = QWidget()
    main_layout = QVBoxLayout()
    main_layout.setContentsMargins(16, 16, 16, 16)
    main_layout.setSpacing(16)

    # Title
    title = QLabel("Card Game")
    title.setStyleSheet("font-weight: bold; font-size: 20px;")
    title.setAlignment(Qt.AlignmentFlag.AlignCenter)
    main_layout.addWidget(title)

    # Game board section
    board_label = QLabel("Game Board")
    board_label.setStyleSheet("font-weight: bold; font-size: 14px; color: #555;")
    main_layout.addWidget(board_label)

    # Player cards
    player_frame = QFrame()
    player_frame.setStyleSheet("""
        QFrame {
            background-color: #f0f0f0;
            border-radius: 6px;
            padding: 12px;
        }
    """)
    player_layout = QVBoxLayout()
    
    player_label = QLabel("Your Hand")
    player_label.setStyleSheet("font-size: 12px; color: #666;")
    player_layout.addWidget(player_label)
    
    cards_layout = QHBoxLayout()
    suits = ['♠', '♥', '♦', '♣']
    ranks = ['A', '2', '3', '4', '5']
    for i, rank in enumerate(ranks):
        suit = suits[i % len(suits)]
        cards_layout.addWidget(create_card_widget(suit, rank))
    cards_layout.addStretch()
    player_layout.addLayout(cards_layout)
    
    player_frame.setLayout(player_layout)
    main_layout.addWidget(player_frame)

    # Opponent cards
    opponent_frame = QFrame()
    opponent_frame.setStyleSheet("""
        QFrame {
            background-color: #f0f0f0;
            border-radius: 6px;
            padding: 12px;
        }
    """)
    opponent_layout = QVBoxLayout()
    
    opponent_label = QLabel("Opponent's Hand")
    opponent_label.setStyleSheet("font-size: 12px; color: #666;")
    opponent_layout.addWidget(opponent_label)
    
    opponent_cards = QHBoxLayout()
    for i in range(3):
        card = QFrame()
        card.setStyleSheet("""
            QFrame {
                background-color: #1a5f9f;
                border: 2px solid #0d3a6b;
                border-radius: 8px;
            }
        """)
        card.setFixedSize(80, 120)
        opponent_cards.addWidget(card)
    opponent_cards.addStretch()
    opponent_layout.addLayout(opponent_cards)
    
    opponent_frame.setLayout(opponent_layout)
    main_layout.addWidget(opponent_frame)

    # Control buttons
    button_layout = QHBoxLayout()
    button_layout.setSpacing(10)
    
    play_button = QPushButton("Play Card")
    play_button.setStyleSheet("""
        QPushButton {
            background-color: #4CAF50;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            font-weight: bold;
        }
        QPushButton:hover {
            background-color: #45a049;
        }
    """)
    
    pass_button = QPushButton("Pass")
    pass_button.setStyleSheet("""
        QPushButton {
            background-color: #2196F3;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            font-weight: bold;
        }
        QPushButton:hover {
            background-color: #0b7dda;
        }
    """)
    
    button_layout.addWidget(play_button)
    button_layout.addWidget(pass_button)
    button_layout.addStretch()
    
    main_layout.addLayout(button_layout)

    # Config info (collapsed)
    config_info = QLabel(f"Game Config: {len(config)} settings loaded")
    config_info.setStyleSheet("font-size: 11px; color: #999;")
    main_layout.addWidget(config_info)

    main_layout.addStretch()
    container.setLayout(main_layout)
    return container

# Main function for standalone execution (if run directly)
def main():
    app = QApplication(sys.argv)
    config = read_game_config('game_config.txt')
    widget = create_game_widget(config)
    widget.setWindowTitle('Card Game')
    widget.setGeometry(100, 100, 800, 600)
    widget.show()
    sys.exit(app.exec())

if __name__ == '__main__':
    main()
