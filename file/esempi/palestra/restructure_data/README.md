# Restructuring CSV Data with Miller

This example demonstrates how to fix a malformed CSV file structure using Miller (mlr), a powerful command-line tool for data transformation.

## Problem Description

Sometimes CSV files can have incorrect structures, such as:
- Wrong column headers
- Misaligned data
- Inconsistent formatting
- Missing delimiters

## Solution Using Miller

Miller provides powerful commands to restructure and clean CSV data. Here's an example:

```bash
mlr --csv reshape -r "^(.*)_([0-9]+)$" -o "\$1,\$2" input.csv > output.csv
```

This command:
1. Reads a CSV file with malformed column headers like "value_1", "value_2"
2. Restructures it into proper rows and columns
3. Outputs a clean CSV file

## Requirements

- Miller (mlr) installed on your system
- A CSV file that needs restructuring

## Installation

On Debian/Ubuntu systems:
```bash
sudo apt-get install miller
```

## More Information

For more details about Miller's capabilities, visit:
https://miller.readthedocs.io/
