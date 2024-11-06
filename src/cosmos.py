from dotenv import load_dotenv

from azure.core.credentials import AzureNamedKeyCredential
from azure.data.tables import TableServiceClient

import json
import os

def getLastRequestCharge(c):
    return c.client_connection.last_response_headers["x-ms-request-charge"]


def runDemo(writeOutput):
    load_dotenv()

    # <create_client>
    accountName = os.getenv("CONFIGURATION__AZURECOSMOSDB__ACCOUNTNAME")
    if not accountName:
        raise EnvironmentError("Azure Cosmos DB for NoSQL account name not set.")

    endpoint = os.getenv("CONFIGURATION__AZURECOSMOSDB__ENDPOINT")
    if not endpoint:
        raise EnvironmentError("Azure Cosmos DB for NoSQL account endpoint not set.")

    key = os.getenv("CONFIGURATION__AZURECOSMOSDB__KEY")
    if not key:
        raise EnvironmentError("Azure Cosmos DB for NoSQL write key not set.")

    credential = AzureNamedKeyCredential(accountName, key)

    client = TableServiceClient(endpoint=endpoint, credential=credential)
    # </create_client>

    tableName = os.getenv("CONFIGURATION__AZURECOSMOSDB__TABLENAME", "cosmicworks-products")
    table = client.get_table_client(tableName)

    writeOutput(f"Get table:\t{table.table_name}")

    new_entity = {
        "RowKey": "70b63682-b93a-4c77-aad2-65501347265f",
        "PartitionKey": "gear-surf-surfboards",
        "Name": "Yamba Surfboard",
        "Quantity": 12,
        "Sale": False,
    }
    created_entity = table.upsert_entity(new_entity)

    writeOutput(f"Upserted entity:\t{created_entity}")

    new_entity = {
        "RowKey": "25a68543-b90c-439d-8332-7ef41e06a0e0",
        "PartitionKey": "gear-surf-surfboards",
        "Name": "Kiama Classic Surfboard",
        "Quantity": 4,
        "Sale": True,
    }
    created_entity = table.upsert_entity(new_entity)
    writeOutput(f"Upserted entity:\t{created_entity}")

    existing_item = table.get_entity(
        row_key="70b63682-b93a-4c77-aad2-65501347265f",
        partition_key="gear-surf-surfboards",
    )

    writeOutput(f"Read entity id:\t{existing_item['RowKey']}")
    writeOutput(f"Read entity:\t{existing_item}")

    category = "gear-surf-surfboards"
    filter = f"PartitionKey eq '{category}'"
    entities = table.query_entities(query_filter=filter)

    result = []
    for entity in entities:
        result.append(entity)

    output = json.dumps(result, indent=True)

    writeOutput("Found entities:")
    writeOutput(output, isCode=True)