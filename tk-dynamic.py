import tkinter as tk
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("TkAgg")
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2TkAgg
from matplotlib.figure import Figure

class Root(tk.Tk):
    def __init__(self):
        super().__init__()

        self.title("DataApp")
        self.geometry("200x100")
        self.configure(background='gray')

        frame1 = tk.Frame(self)
        frame1.pack(side=tk.TOP)
        row_lab = tk.Label(frame1, text="Rows:")
        row_lab.pack(side=tk.LEFT)
        self.rows = tk.Text(frame1, height=1, bg="white", fg="black")
        self.rows.pack(side=tk.LEFT)
        self.rows.insert(tk.END, "4")
        self.rows.focus_set()

        frame2 = tk.Frame(self)
        frame2.pack(side=tk.TOP)
        col_lab = tk.Label(frame2, text="Cols:")
        col_lab.pack(side=tk.LEFT)
        self.cols = tk.Text(frame2, height=1, bg="white", fg="black")
        self.cols.pack(side=tk.LEFT)
        self.cols.insert(tk.END, "4")

        btn = tk.Button(self, text="New", command=self.new_data)
        btn.pack()

    def new_data(self):
        rows = self.rows.get(1.0, tk.END).strip()
        cols = self.cols.get(1.0, tk.END).strip()

        if int(rows) and int(cols):
            df = pd.DataFrame(np.random.randn(int(rows), int(cols)))
            self.data_grid(df)
            self.data_plot(df)
    
    def data_grid(self, data):
        win = tk.Toplevel()
        win.wm_title("Grid")

        rows = data.shape[0]
        columns = data.shape[1]

        win._widgets = []

        for row in range(rows):
            current_row = []

            for column in range(columns):
                label = tk.Label(win,
                    text="%.3f" % (data.iloc[row,column]), 
                    borderwidth=0, width=10)
                label.grid(row=row, column=column, sticky="nsew", padx=1, pady=1)
                current_row.append(label)

            win._widgets.append(current_row)

        for column in range(columns):
            win.grid_columnconfigure(column, weight=1)

    def data_plot(self, data):
        win = tk.Toplevel()
        win.wm_title("Plot")

        xaxis = np.arange(1, data.shape[1] + 1)

        fig = Figure(figsize=(5,5), dpi=100)
        a = fig.add_subplot(111)

        for n in range(0, data.shape[0]):
            a.plot(xaxis, data.iloc[n])

        # Display the MPL toolbar
        frame = tk.Frame(win)
        frame.grid(row=2, column=0)
        canvas = FigureCanvasTkAgg(fig, master=win)
        NavigationToolbar2TkAgg(canvas, frame)
        canvas.get_tk_widget().grid(row=0, column=0)

if __name__ == "__main__":
    root = Root()
    root.mainloop()