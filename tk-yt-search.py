from roku import Roku
import sqlite3
import time
import tkinter as tk

def go_up():
    global roku
    roku.up()
def go_down():
    global roku
    roku.down()
def go_left():
    global roku
    roku.left()
def go_right():
    global roku
    roku.right()
def go_enter():
    global roku
    roku.enter()

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
    global bottom_left_frame, option, options_list, dropdown, history_button
    dropdown = tk.OptionMenu(bottom_left_frame, option, *options_list)
    dropdown.pack(side=tk.LEFT, padx=5)
    history_button = tk.Button(bottom_left_frame, text="Select", command=show_selected)
    history_button.pack(side=tk.LEFT, padx=5)

def show_selected():
    global option, entry_field
    selected = option.get()
    selected = selected[2:len(selected) - 3]
    entry_field.delete(0, tk.END)
    entry_field.insert(0, selected)

def clear_db():
    global bottom_left_frame, option, options_list, dropdown, history_button
    conn = sqlite3.connect('yt-search.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM search')
    conn.commit()
    conn.close()
    options_list.clear()
    options_list.append('...')
    option.set(options_list[0])
    dropdown.destroy()
    history_button.destroy()
    create_select()

def search_yt():
    global root, bottom_left_frame, v, options_list, option, dropdown, history_button

    root.config(cursor="wait")

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

    root.config(cursor="")

# connect on the default IP
roku = Roku('192.168.100.107')

root = tk.Tk()
root.title("YouTube Search")

top_left_frame = tk.Frame(root)
top_left_frame.pack(side=tk.TOP, anchor=tk.NW, padx=0, pady=0)

home_button = tk.Button(top_left_frame, text="Home", command=go_home)
home_button.pack(side=tk.LEFT, padx=0)

yt_button = tk.Button(top_left_frame, text="YouTube", command=yt_login)
yt_button.pack(side=tk.LEFT, padx=0)

enter_button = tk.Button(top_left_frame, text="Enter", command=go_enter)
enter_button.pack(side=tk.RIGHT, padx=0)
right_button = tk.Button(top_left_frame, text="Right", command=go_right)
right_button.pack(side=tk.RIGHT, padx=0)
left_button = tk.Button(top_left_frame, text="Left", command=go_left)
left_button.pack(side=tk.RIGHT, padx=0)
down_button = tk.Button(top_left_frame, text="Down", command=go_down)
down_button.pack(side=tk.RIGHT, padx=0)
up_button = tk.Button(top_left_frame, text="Up", command=go_up)
up_button.pack(side=tk.RIGHT, padx=0)

mid_left_frame = tk.Frame(root)
mid_left_frame.pack(side=tk.TOP, anchor=tk.NW, padx=10, pady=10)

entry_label = tk.Label(mid_left_frame, text="Search Query:")
entry_label.pack(side=tk.LEFT)

v = tk.StringVar()
entry_field = tk.Entry(mid_left_frame, textvariable=v, width=40)
entry_field.pack()

bottom_left_frame = tk.Frame(root)
bottom_left_frame.pack(side=tk.TOP, anchor=tk.NW, padx=10, pady=10)

clear_button = tk.Button(bottom_left_frame, text="Clear", command=clear_db)
clear_button.pack(side=tk.RIGHT, anchor=tk.NW)

submit_button = tk.Button(bottom_left_frame, text="Submit", command=search_yt)
submit_button.pack(side=tk.RIGHT, anchor=tk.NW)

conn = sqlite3.connect('yt-search.db')
cursor = conn.cursor()
cursor.execute("CREATE TABLE IF NOT EXISTS search (id INTEGER PRIMARY KEY, query TEXT)")
cursor.execute("SELECT query FROM search")
rows = cursor.fetchall()
conn.close()

options_list = ['...']
for i in rows:
    options_list.append(str(i))
option = tk.StringVar(bottom_left_frame)
option.set(options_list[0])
dropdown = None
history_button = None
create_select()

root.mainloop()
