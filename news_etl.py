import pandas as pd
import logging
import sqlite3
from newsapi import NewsApiClient

# Import additional libraries
from datetime import datetime, timedelta, time
from airflow import DAG
from airflow.operators.python import PythonOperator

# Initialize NewsApiClient
news_api_key = "889a3707d64b4695aabb3a24040c9ab7"  # Replace with your actual API key
news_api = NewsApiClient(api_key=news_api_key)

# Assign datetime variables
to_date = datetime.utcnow().date()
from_date = to_date - timedelta(days=-1)

# Intialize DAG object
dag = DAG(
    dag_id='news_etl',
    default_args={'start_date' : datetime.combine(from_date, time(0, 0)), retries : 1},
    schedule_interval= '@daily'
)
def extract_news_data(**kwargs):
    try: 
        result = news_api.get_everything(q="AI", language="en", from_param=from_date, to=to_date)
        logging.info("Connection is successful.")
        
        # Push the result to XCom
        kwargs[task_instance].xcom_push(key = 'extract_result', value = result['articles'])


    except:
        logging.error("Connection is unsuccessful.")
    
def clean_author_column(text):    
    try:
        return text.split(",")[0].title()
    except AttributeError:
        return "No Author"
    
def transform_news_data(**kwargs):
    article_list = []
    
    # Add XCom pull logic to pull data from XCom
    data = kwargs['task_instance'].xcom_pull(task_ids = 'extract_news', key = 'extract_result')
    
    # Logging message after XCom pull
    logging.info("Data pulled successfully.")

    for i in data:
        article_list.append([value.get("name", 0) if key == "source" else value for key, value in i.items() 
                          if key in ["author", "title", "publishedAt", "content", "url", "source"]])

    df = pd.DataFrame(article_list, columns=["Source", "Author Name", "News Title", "URL", "Date Published", "Content"])

    df["Date Published"] = pd.to_datetime(df["Date Published"]).dt.strftime('%Y-%m-%d %H:%M:%S')

    df["Author Name"] = df["Author Name"].apply(clean_author_column)
    
    # Add XCom push logic to push data to XCom
    kwargs['task_instance'].xcom_push(key = 'transform_df', value = df.to_json())

    # Logging message after XCom push

    logging.info("Transformed data pushed to XCom successfully.")

def load_news_data(**kwargs):
    with sqlite3.connect("/usercode/etl_news_data.sqlite") as connection:
        # Create a cursor within the context manager
        cursor = connection.cursor()

        # Create a table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS news_table (
                "Source" VARCHAR(30),
                "Author Name" TEXT,
                "News Title" TEXT,
                "URL" TEXT,
                "Date Published" TEXT,
                "Content" TEXT
            )
        ''')

        # Pull data from XCom
        data = kwargs['task_instance'].xcom_pull(task_ids = 'transform_news', key = 'transform_df')
        
        # Convert data into a DataFrame
        df = pd.read_json(data)

        # Logging message before loading data
        logging.info("Ready to load data into the database.")

        df.to_sql(name="news_table", con=connection, index=False, if_exists="append")
        
        # Logging message after loading data
        logging.info("Data successfully loaded into the database.")

# Create Python operators

_extract_news_data = PythonOperator(
    task_id = 'extract_news',
    python_callable = 'extract_news_data',
    provide_context = True,
    dag = dag
)
_transform_news_data = PythonOperator(
    task_id = 'transform_news',
    python_callable= 'transform_news_data',
    provide_context = True,
    dag = dag
)

_load_news_data = PythonOperator(
    task_id = 'load_news',
    python_callable= 'load_news_data',
    provide_context = True,
    dag = dag
)

# Create depedencies
_extract_news_data >> _transform_news_data >> _load_news_data

