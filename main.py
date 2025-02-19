print("running main")
import sys
from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QApplication
from MainWindow import MainWindow

def load_stylesheet(file_path):
    with open(file_path, "r") as file:
        return file.read() 

if __name__ == "__main__":
    app = QApplication(sys.argv)
    stylesheet = load_stylesheet("styles/app.qss")
    app.setStyleSheet(stylesheet)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
