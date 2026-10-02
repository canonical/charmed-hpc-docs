#!/usr/bin/env python3

"""Plot the most popular Ubuntu LTS mascot."""

import argparse

import pandas as pd

WIDTH = 150
TITLE = "Favorite LTS mascot"

def main(dataset: str, output: str) -> None:
    mascots = pd.read_csv(dataset)["favorite_lts_mascot"].value_counts().sort_index()

    peak = mascots.max()
    name_w = len(max(mascots.index, key=len)) + 1
    bar_w = WIDTH - name_w - len(f"{peak:.2f}") - 2

    lines = [f" {TITLE} ".center(WIDTH, "─")]

    for name, count in mascots.items():
        bar = "▇" * round(count / peak * bar_w)
        lines.append(f"│{name:<{name_w}}{bar} {count:.2f}")

    chart = "\n".join(lines) + "\n"

    if output:
        with open(output, "w") as f:
            f.write(chart)
    else:
        print(chart, end="")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("dataset", help="Path to CSV dataset to plot")
    parser.add_argument("-o", "--output", default="", help="Output file to save plotted graph")
    args = parser.parse_args()

    main(args.dataset, args.output)
