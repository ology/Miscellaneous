from roku import Roku
import sqlite3
import time
import tkinter as tk

def show_selected():
    selected = option.get()
    selected = selected[2:len(selected) - 3]
    entry_field.delete(0, tk.END)
    entry_field.insert(0, selected)

def search_yt():
    global dropdown
    query = v.get()
    with sqlite3.connect('yt-search.db') as conn:
        cursor.execute("INSERT INTO search (query) VALUES (?)", (query,))
        conn.commit()
        options_list.append(query)
        dropdown.destroy()
        dropdown = tk.OptionMenu(root, option, *options_list)
        dropdown.pack(pady=20)
        # conn.close()
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

conn = sqlite3.connect('yt-search.db')
cursor = conn.cursor()

root = tk.Tk()
root.title("YouTube Search")
entry_label = tk.Label(root, text="Search Query:")
entry_label.pack()
v = tk.StringVar()
entry_field = tk.Entry(root, textvariable=v, width=40)
entry_field.pack()
submit_button = tk.Button(root, text="Submit", command=search_yt)
submit_button.pack()

options_list = []
with sqlite3.connect('yt-search.db') as conn:
    cursor.execute("SELECT query FROM search")
    rows = cursor.fetchall()
    for i in rows:
        options_list.append(i)
    option = tk.StringVar(root)
    option.set(options_list[0])
    dropdown = tk.OptionMenu(root, option, *options_list)
    dropdown.pack(pady=20)
    history_button = tk.Button(root, text="Select", command=show_selected)
    history_button.pack()

root.mainloop()
