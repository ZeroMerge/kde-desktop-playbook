import dbus
import sys

try:
    bus = dbus.SessionBus()
    obj = bus.get_object("org.kde.plasmashell", "/PlasmaShell")
    iface = dbus.Interface(obj, "org.kde.PlasmaShell")
    code = """
var p = panelById(80);
var n = (p.hiding === "none") ? "dodgewindows" : "none";
p.hiding = n;
print(n);
"""
    res = iface.evaluateScript(code)
    sys.stdout.write(res.strip())
except Exception as e:
    sys.stdout.write("dodgewindows")
