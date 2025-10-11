from roku import Roku
import time
import sys
import tkinter as tk

def show_input():
    query = my_string_var.get()

    roku = Roku('192.168.100.107')

    roku.home()
    time.sleep(10)

    app = roku['YouTube']
    app.launch()

    time.sleep(10)
    roku.left()
    roku.up()
    roku.enter()
    time.sleep(2)

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

root = tk.Tk()
root.title("YouTube Search")

my_string_var = tk.StringVar()

entry_label = tk.Label(root, text="Search Query:")
entry_label.pack()

entry_field = tk.Entry(root, textvariable=my_string_var, width=40)
entry_field.pack()

submit_button = tk.Button(root, text="Submit", command=show_input)
submit_button.pack()

root.mainloop()