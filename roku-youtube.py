from roku import Roku
import time
import sys

roku = Roku('192.168.100.107')

app = roku['YouTube']
# app = roku['Playlet']
app.launch()

time.sleep(10)
roku.left()
roku.up()
roku.enter()
time.sleep(2)

query = sys.argv[1] if len(sys.argv) > 1 else "python programming"

for char in query:
    roku.literal(char)
    time.sleep(0.5)

roku.down()
roku.down()
roku.down()
roku.down()
roku.right()
roku.right()
roku.right()
roku.enter()
