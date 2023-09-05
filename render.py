"""This is to use the provided parameters to render a query and use
that to collect relevant data from the database and write the output
in a text file.

To run it pass the below arguments:
path to the query file, path to the parameters json file and the
name of the output file."""

import json
import logging
import os
import sys

import psycopg2
from jinja2 import Template
from prettytable import PrettyTable
import argparse
from dotenv import load_dotenv

# QUERY_FILE_PATH = sys.argv[1]
# QUERY_PARAMS_PATH = sys.argv[2]
# OUTPUT_FILE_NAME = sys.argv[3]

load_dotenv()

DB_USER = os.getenv("DB_USER")
DATABASE = os.getenv("DATABASE")
HOST = os.getenv("HOST")
PORT = os.getenv("PORT")
# DB_PASSWORD = os.getenv("DB_PASSWORD")

db_creds = {
    'user': DB_USER,
    'database': DATABASE,
    'host': HOST,
    'port': PORT
}

# Configure logging
log_file = os.path.join(os.getcwd(), 'render.log')
logging.basicConfig(level=logging.INFO, filename=log_file,
                    format='%(asctime)s - %(levelname)s - %(message)s')


def process_query_params(params_file: str) -> dict:
    """This is to read the query parameters from a json file.

    Args:
        params_file (str): Json file consisting all required
            parameters for the query.

    Returns:
        dict: Query parameters is a dictionary format.
    """
    with open(params_file, 'r', encoding="utf-8") as our_params_file:
        query_params = json.load(our_params_file)

    return query_params


def render_query(file_path: str, params: dict) -> str:
    """This gets the path to the query file and required parameters
    and returns the rendered query.

    Args:
        file_path (str): file path where the raw query is saved.
        params (dict): query parameters.

    Returns:
        str: Returns the rendered query.
    """

    # Read the SQL template from the file
    with open(file_path, 'r', encoding="utf-8") as sql_file:
        sql_template = sql_file.read()

    template = Template(sql_template)
    context = {'request_persona_id': params['request_persona_id'],
               'inputs': params['inputs']}

    sql_query = template.render(context)

    return sql_query


def query_db(query: str, db_cred: dict, file_name: str) -> list:
    """This is to query the database using the rendered query and
    database credentials. The outcome is written in a file using the
    given file name in the results directory.

    Args:
        query (str): Rendered query received from render_query
            function.
        db_cred (dict): This is the credentials of the db.
        file_name (str): This is the file name output is written in
            results directory.

    Returns:
        list: Returns list of returned results, each individual result
            is a tuple.
    """

    results = []
    try:
        conn = psycopg2.connect(**db_cred)
        cursor = conn.cursor()

        cursor.execute(query)

        results = cursor.fetchall()

        report_table = PrettyTable()
        report_table.field_names = [column[0] for column in cursor.description]

        for row in results:
            report_table.add_row(row)

        with open(f'results/{file_name}.txt', 'w') as file:
            file.write(str(report_table))

        logging.info("Query output successfully written.")

    except psycopg2.Error as err:
        logging.error(f"Database error: {err}")

    except Exception as err:
        logging.error(f"An error occurred: {err}")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


def main() -> None:
    """Main function running the whole process.

    Returns:
        None: None
    """
    # Create an ArgumentParser object
    parser = argparse.ArgumentParser(description='My PostgreSQL Task')

    # Add argument options
    parser.add_argument('--parameters_file', required=True,
                        help='Path to the parameters file')
    parser.add_argument('--query_file', required=True,
                        help='Path to the query file')
    parser.add_argument('--output_file', required=True,
                        help='Path to the output file')

    # Parse the command-line arguments
    args = parser.parse_args()

    # Access the argument values
    parameters_file = args.parameters_file
    query_file = args.query_file
    output_file = args.output_file

    query_params = process_query_params(parameters_file)
    rendered_query = render_query(query_file, query_params)
    query_db(rendered_query, db_creds, output_file)


if __name__ == "__main__":
    main()

