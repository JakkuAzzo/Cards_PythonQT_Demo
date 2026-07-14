"""Small offline desktop edition of Cards, packaged for macOS and Windows."""
import random
import tkinter as tk
from tkinter import ttk

PROMPTS = [
    "What is a hill you are willing to die on?",
    "What would make tonight unforgettable?",
    "Which place would you revisit tomorrow?",
    "What is a tiny skill everyone should learn?",
]


class CardsDesktop(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Cards")
        self.minsize(560, 480)
        self.configure(bg="#080a10", padx=28, pady=26)
        self.deck = []
        self.players = ["You"]
        self.status = tk.StringVar(value="Lobby · add a nearby player to begin")
        self.card = tk.StringVar(value="Start a table to draw a prompt.")
        self._build()

    def _build(self):
        tk.Label(self, text="CARDS · LOCAL-FIRST", fg="#f5b72b", bg="#080a10", font=("Arial", 11, "bold")).pack(anchor="w")
        tk.Label(self, text="Live Table", fg="white", bg="#080a10", font=("Arial", 28, "bold")).pack(anchor="w", pady=(3, 2))
        tk.Label(self, textvariable=self.status, fg="#c4c9d4", bg="#080a10", font=("Arial", 12)).pack(anchor="w", pady=(0, 18))
        self.card_label = tk.Label(self, textvariable=self.card, fg="#17100b", bg="#f5f1e7", wraplength=460, justify="center", font=("Arial", 18, "bold"), padx=30, pady=48)
        self.card_label.pack(fill="x")
        self.controls = tk.Frame(self, bg="#080a10")
        self.controls.pack(fill="x", pady=18)
        self.join_button = self.button("Simulate nearby player", self.join)
        self.start_button = self.button("Start table", self.start)
        self.draw_button = self.button("Draw prompt", self.draw)
        self.end_button = self.button("End turn", self.end_turn)
        for button in (self.join_button, self.start_button, self.draw_button, self.end_button):
            button.pack(side="left", padx=(0, 8))
        self.start_button.configure(state="disabled")
        self.draw_button.configure(state="disabled")
        self.end_button.configure(state="disabled")
        tk.Label(self, text="Offline preview · Nearby transport and AR are available in the native mobile apps.", fg="#8d95a5", bg="#080a10", font=("Arial", 10)).pack(anchor="w")

    def button(self, label, command):
        return tk.Button(self.controls, text=label, command=command, bg="#f5b72b", fg="#16110a", relief="flat", padx=12, pady=9, font=("Arial", 11, "bold"))

    def join(self):
        self.players.append(f"Player {len(self.players) + 1}")
        self.status.set("Lobby · " + " · ".join(self.players))
        self.start_button.configure(state="normal")
        self.join_button.configure(state="disabled")

    def start(self):
        self.deck = random.sample(PROMPTS, len(PROMPTS))
        self.status.set("Table active · You draw first · " + " · ".join(self.players))
        self.start_button.configure(state="disabled")
        self.draw_button.configure(state="normal")

    def draw(self):
        if not self.deck:
            self.card.set("The prompt deck is complete. Start a new table to play again.")
            self.draw_button.configure(state="disabled")
            return
        self.card.set(self.deck.pop())
        self.status.set(f"Your turn · {len(self.deck)} cards left")
        self.draw_button.configure(state="disabled")
        self.end_button.configure(state="normal")

    def end_turn(self):
        self.status.set("Player 2's turn · local preview")
        self.card.set("Pass the device, then continue the conversation.")
        self.end_button.configure(state="disabled")


if __name__ == "__main__":
    CardsDesktop().mainloop()
