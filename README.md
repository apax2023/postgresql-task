# My PostgreSQL Task

This is to show the work I did for PostgreSQL task.

## Installation

To get started, follow these steps to set up your environment:

1. Clone this repository:
```bash 
git clone https://github.com/yourusername/my-postgreSQL-task.git
cd my-postgreSQL-task
```

2. Create and activate a virtual environment (recommended):
```bash
python -m venv venv
source venv/bin/activate # On Windows, use: venv\Scripts\activate
```

3. Install the required Python packages:
```bash
pip install -r requirements.txt
```

### Environment Variables

To securely manage configuration settings, environment variables are defined and used.

**In Your `.env` File (Recommended for Local Development)**:

Create a `.env` file in your project directory and define environment variables with values. For example:

```plaintext
DB_USER=your_db_user
DATABASE=your_database
HOST=your_host
PORT=your_port
```


## How to Run the code

You can run the app by executing the `render.py` script with the following required arguments:
```bash
python render.py --parameters_file paramseters_file_path --query_file query_file_path --output_file journey_7.txt
```
This will get the parameters and query from the given files and writes the outcome of the query in .txt format with 
a given name in results directory.

### Arguments

- `--parameters_file`: Path to the parameters file.
- `--query_file`: Path to the query file.
- `--output_file`: Name of the output file.

### Example

For example, to run the code with params.josn file and rjah-patient-list-report query:

```bash
python render.py --parameters_file params.json --query_file rjah-patient-list-report.sql --output_file journey_7.txt
```

Make sure to replace the parameters and query file paths with your own, and choose an output file name.

### Parameters
By changing the parameters and re running the code the output changes. Below is an example of the parameters that could
be passed:

```json
{
    "request_persona_id": 3832,
    "inputs": {
        "filter": {
            "text_search": "0d24e6c8b23b04a7c5ed3a1b728f8c61",
            "operation": {"start_date": "2019-01-01",
                          "end_date": "2021-07-30"},
            "registration": {"exists": true},
            "journey_slug": ["journey-7", "journey-5"],
            "side": "right"
        },
        "page": {"index": 0, "size": 100}
    }
}
```

## License

This project is licensed under the .... (LICENSE).
