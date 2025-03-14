#!/usr/bin/env python3

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GdkPixbuf, Gdk
import os
import subprocess
import getpass

# Vars
USER = getpass.getuser()
WALLS_DIR = os.path.expanduser("~/walls")
CONFIG_DIR = os.path.expanduser("~/.config/swww")
WALLPAPER_FILE = os.path.join(CONFIG_DIR, "current_wallpaper")

# Sicherstellen, dass Verzeichnisse existieren
if not os.path.exists(CONFIG_DIR):
    os.makedirs(CONFIG_DIR)
if not os.path.exists(WALLS_DIR):
    os.makedirs(WALLS_DIR)

# Catppuccin Mocha CSS
CSS = """
window {
    background-color: #1E1E2E;
    color: #CDD6F4;
}
label {
    color: #CDD6F4;
}
button, button.flat {
    background-color: #313244;
    color: #CDD6F4;
    border: 1px solid #B4BEFE;
    border-radius: 5px;
    padding: 5px 10px;
    background-image: none;
    box-shadow: none;
}
button:hover, button.flat:hover {
    background-color: #B4BEFE;
    color: #1E1E2E;
    border: 1px solid #B4BEFE;
}
button:active, button.flat:active {
    background-color: #F5E0DC;
    color: #1E1E2E;
}
iconview {
    background-color: #181825;
}
iconview:selected {
    background-color: #B4BEFE;
    border: 2px solid #F5E0DC;
    border-radius: 5px;
}
iconview:selected:focus {
    background-color: #B4BEFE;
    border: 2px solid #F5E0DC;
}
"""

class WallpaperChanger(Gtk.Window):
    def __init__(self):
        super().__init__(title="Wallpaper Changer (swww)")
        self.set_border_width(10)
        self.set_default_size(600, 400)

        # CSS für Catppuccin anwenden
        style_provider = Gtk.CssProvider()
        style_provider.load_from_data(CSS.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Hauptbox
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(vbox)

        # Label für aktuelles Wallpaper
        self.current_label = Gtk.Label(label="Current Wallpaper: Not set")
        vbox.pack_start(self.current_label, False, False, 0)
        self.update_current_wallpaper_label()

        # Scrolled Window für IconView
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        vbox.pack_start(scrolled, True, True, 0)

        # IconView für Wallpaper-Vorschau
        self.iconview = Gtk.IconView()
        self.iconview.set_pixbuf_column(0)
        self.iconview.set_text_column(-1)
        self.iconview.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.iconview.connect("selection-changed", self.on_selection_changed)
        self.iconview.set_item_orientation(Gtk.Orientation.HORIZONTAL)
        self.iconview.set_columns(-1)
        self.iconview.set_item_width(120)
        self.iconview.set_spacing(10)
        self.iconview.set_row_spacing(10)
        scrolled.add(self.iconview)

        # Model für IconView (Pixbuf, Name)
        self.store = Gtk.ListStore(GdkPixbuf.Pixbuf, str)
        self.load_wallpapers()

        self.iconview.set_model(self.store)

        # Button zum Setzen des Wallpapers
        set_button = Gtk.Button(label="Set Selected Wallpaper")
        set_button.get_style_context().add_class("flat")
        set_button.connect("clicked", self.on_set_button_clicked)
        vbox.pack_start(set_button, False, False, 0)

    def load_wallpapers(self):
        """Lade alle Bilddateien aus ~/walls mit Vorschau."""
        self.store.clear()
        for filename in os.listdir(WALLS_DIR):
            filepath = os.path.join(WALLS_DIR, filename)
            if os.path.isfile(filepath) and filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp')):
                try:
                    pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(filepath, 100, 100, True)
                    self.store.append([pixbuf, filename])
                except Exception as e:
                    print(f"Fehler beim Laden von {filename}: {e}")

    def update_current_wallpaper_label(self):
        """Aktualisiere das Label mit dem aktuellen Wallpaper."""
        if os.path.exists(WALLPAPER_FILE):
            with open(WALLPAPER_FILE, "r") as f:
                current_wallpaper = f.read().strip()
            self.current_label.set_text(f"Current Wallpaper: {os.path.basename(current_wallpaper)}")
        else:
            self.current_label.set_text("Current Wallpaper: Not set")

    def on_selection_changed(self, iconview):
        """Wenn ein Wallpaper ausgewählt wird."""
        selected = iconview.get_selected_items()
        if selected:
            tree_iter = self.store.get_iter(selected[0])
            self.selected_filename = self.store.get_value(tree_iter, 1)

    def on_set_button_clicked(self, widget):
        """Setze das ausgewählte Wallpaper."""
        if hasattr(self, "selected_filename"):
            filepath = os.path.join(WALLS_DIR, self.selected_filename)
            self.set_wallpaper(filepath)
        else:
            dialog = Gtk.MessageDialog(
                parent=self,
                flags=0,
                message_type=Gtk.MessageType.WARNING,
                buttons=Gtk.ButtonsType.OK,
                text="Bitte wähle ein Wallpaper aus!",
            )
            dialog.run()
            dialog.destroy()

    def set_wallpaper(self, filepath):
        """Setze das Wallpaper mit swww und führe matugen aus."""
        try:
            subprocess.run([
                "swww", "img", filepath,
                "--transition-type", "grow",
                "--transition-duration", "2",
                "--transition-fps", "60"
            ], check=True)
            subprocess.run([f"/home/{USER}/.cargo/bin/matugen", "image", filepath], check=True)
            with open(WALLPAPER_FILE, "w") as f:
                f.write(filepath)
            self.update_current_wallpaper_label()
        except subprocess.CalledProcessError as e:
            error_dialog = Gtk.MessageDialog(
                parent=self,
                flags=0,
                message_type=Gtk.MessageType.ERROR,
                buttons=Gtk.ButtonsType.OK,
                text=f"Fehler beim Setzen des Wallpapers oder Ausführen von matugen: {e}",
            )
            error_dialog.run()
            error_dialog.destroy()

def main():
    win = WallpaperChanger()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()

