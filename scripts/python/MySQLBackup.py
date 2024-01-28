# Script Name: MySQLBackup.py
# Author: Harley Frank
# Created: 01/27/2024
# Last Modified: 01/27/2024
# Description: This script will backup all MySQL databases on a server.

# Notes:
# This script requires the mysql-connector-python module. To install it, run 'pip3 install mysql-connector-python' in the terminal.
# Additionally, this script requires that MySQL is installed on the machine that it is running on. To install MySQL, run 'brew install mysql' in the terminal.

# Import Working Modules
import mysql.connector
import subprocess
import os

# General Variables
host = 'insert IP address here'
username = 'root'
password = 'insert password here'
output_path = os.path.expanduser("~/Documents/Recovery/mysql-database-backups")

# MySQL connection configuration
config = {
    'user': username,
    'password': password,
    'host': host,
    'database': 'information_schema',
    'raise_on_warnings': True,
    'port': 3306
}

# Establish a connection to the MySQL server
cnx = mysql.connector.connect(**config)

# Create a cursor object
cursor = cnx.cursor()

# Execute a query to get a list of all databases
cursor.execute("SHOW DATABASES")

# Loop through each database
for (database_name,) in cursor:
    # Print the database name
    # print(database_name)

    # Define the command to export the database
    command = 'mysqldump -h ' + host + ' -u root -p"' + password + '" --databases {} > {}/{}.sql'.format(database_name, output_path, database_name)

    # Run the command
    subprocess.run(command, shell=True)
    
# Close the cursor and connection
cursor.close()
cnx.close()
