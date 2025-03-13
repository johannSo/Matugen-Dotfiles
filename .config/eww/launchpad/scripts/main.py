import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gio
import json
import subprocess, sys

user = subprocess.check_output(['whoami']).strip().decode("utf-8")
CONFIG_PATH = f'/home/{user}/.config/eww/launchpad/'

class AppLauncher:
	def __init__(self):
		self.config_path = CONFIG_PATH

	def get_gtk_icon(self, icon_name):
		theme = Gtk.IconTheme.get_default()
		icon_info = theme.lookup_icon(icon_name, 128, 0)

		if icon_info is not None:
			return icon_info.get_filename()

	def get_apps(self):
		all_apps = Gio.AppInfo.get_all()
		apps_info = []
		for app in all_apps:
			app_info = self.get_app_info(app)
			if app_info:
				apps_info.append(app_info)
		return json.dumps(apps_info)

	def get_app_info(self, app):
		try:
			icon_name = app.get_icon().get_names()[0] if app.get_icon() else None
		except AttributeError:
			icon_name = None
		icon_path = self.get_gtk_icon(icon_name) if icon_name else None
		desktop_file = app.get_filename()
		if desktop_file:
			app_info = self.get_app_info_from_desktop_file(app, desktop_file)
			if app_info:
				app_info["command"] = self.get_command(app, app_info["terminal"])
				app_info["icon"] = icon_path
				return app_info
		return None

	def get_app_info_from_desktop_file(self, app, desktop_file):
		with open(desktop_file, 'r', encoding='utf-8', errors='ignore') as f:
			contents = f.readlines()
			nodisplay = False
			terminal = False
			for line in contents:
				if line.startswith('NoDisplay='):
					nodisplay = line.split('=')[1].strip() == 'true'
				elif line.startswith('Terminal='):
					terminal = line.split('=')[1].strip() == 'true'
				if nodisplay or terminal:
					break
			f.close()
			if not nodisplay:
				return {
					"name": app.get_display_name(),
					"description": app.get_description(),
					"terminal": terminal
				}
		return None

	def get_command(self, app, terminal):
		command = app.get_executable()
		if terminal:
			command = 'kitty ' + command
		if command.startswith('/usr/bin/flatpak'):
			command += ' run ' + app.get_id().replace('.desktop', '')
		return command

	def close_app(self):
		subprocess.run(['eww', 'close', 'app-launcher', '-c', self.config_path])

	def run(self):
		apps_json = self.get_apps()
		apps = json.loads(apps_json)

		if len(sys.argv) > 2:
			if sys.argv[1] == "-s":
				search = sys.argv[2]
				filtered_apps = list(filter(lambda app: search.lower() in app['name'].lower(), apps))
				grid = [filtered_apps[i:i+8] for i in range(0, len(filtered_apps), 8)]
				subprocess.run(['eww', 'open', 'app-launcher', '-c', self.config_path])
				subprocess.run(['eww', '-c', self.config_path, 'update', 'filter-text={}'.format(json.dumps(grid))])
		else:
			grid = [apps[i:i+8] for i in range(0, len(apps), 8)]
			subprocess.run(['eww', 'open', 'app-launcher', '-c', self.config_path])
			subprocess.run(['eww', '-c', self.config_path, 'update', 'filter-text={}'.format(json.dumps(grid))])

if __name__ == "__main__":
	launcher = AppLauncher()
	launcher.run()
