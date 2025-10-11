from roku import Roku

roku = Roku('192.168.100.107')

app = roku['YouTube']
app.launch()