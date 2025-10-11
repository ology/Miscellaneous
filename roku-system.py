from roku import Roku
import time

roku = Roku('192.168.100.107')

print(roku.device_info)
print()
print(roku.commands)
print()
for app in roku.apps:
    print(app.name)
