from roku import Roku
import sqlite3
import time
import tkinter as tk

def yt_login():
    global roku
    roku.home()
    time.sleep(10)
    app = roku['YouTube']
    app.launch()
    time.sleep(10)
    roku.enter()

def go_home():
    global roku
    roku.home()

def create_select():
    global root, option, options_list, dropdown, history_button
    dropdown = tk.OptionMenu(root, option, *options_list)
    dropdown.pack(pady=5)
    history_button = tk.Button(root, text="Select", command=show_selected)
    history_button.pack()

def show_selected():
    global option, entry_field
    selected = option.get()
    selected = selected[2:len(selected) - 3]
    entry_field.delete(0, tk.END)
    entry_field.insert(0, selected)

def search_yt():
    global v, options_list, option, dropdown, history_button

    query = v.get()
    if not query:
        return

    conn = sqlite3.connect('yt-search.db')
    cursor = conn.cursor()
    cursor.execute("INSERT INTO search (query) VALUES (?)", (query,))
    conn.commit()
    conn.close()
    options_list.append(query)
    dropdown.destroy()
    history_button.destroy()
    create_select()

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

# connect on the default IP
roku = Roku('192.168.100.107')

root = tk.Tk()
root.title("YouTube Search")

home_button = tk.Button(root, text="Home", command=go_home)
home_button.pack()

yt_button = tk.Button(root, text="YouTube", command=yt_login)
yt_button.pack()

entry_label = tk.Label(root, text="Search Query:")
entry_label.pack()

v = tk.StringVar()
entry_field = tk.Entry(root, textvariable=v, width=40)
entry_field.pack()

submit_button = tk.Button(root, text="Submit", command=search_yt)
submit_button.pack()

conn = sqlite3.connect('yt-search.db')
cursor = conn.cursor()
cursor.execute("CREATE TABLE IF NOT EXISTS search (id INTEGER PRIMARY KEY, query TEXT)")
cursor.execute("SELECT query FROM search")
rows = cursor.fetchall()
conn.close()

options_list = ['...']
for i in rows:
    options_list.append(i)
option = tk.StringVar(root)
option.set(options_list[0])
create_select()

root.mainloop()
