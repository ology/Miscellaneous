from roku import Roku
import time
import tkinter as tk

def search_yt():
    query = my_string_var.get()
    # connect on the default IP
    roku = Roku('192.168.100.107')
    # start from the home screen
    roku.home()
    time.sleep(10) # make sure it loaded
    # fire-up youtube
    app = roku['YouTube']
    app.launch()
    time.sleep(10) # make sure it loaded
    # go to the youtube search
    roku.left()
    roku.up()
    roku.enter()
    time.sleep(2) # make sure it loaded
    # enter the query
    for char in query:
        roku.literal(char)
        time.sleep(0.5) # small pause after each
    # click the search button
    for _ in range(4):
        roku.down()
    for _ in range(3):
        roku.right()
    roku.enter()

root = tk.Tk()
root.title("YouTube Search")
my_string_var = tk.StringVar()
entry_label = tk.Label(root, text="Search Query:")
entry_label.pack()
entry_field = tk.Entry(root, textvariable=my_string_var, width=40)
entry_field.pack()
submit_button = tk.Button(root, text="Submit", command=search_yt)
submit_button.pack()
root.mainloop()