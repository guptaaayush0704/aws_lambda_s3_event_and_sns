# -------------------------------------   PLEASE READ   ------------------------------------------
# PURPOSE: This Python script is intended to be used as a AWS Lambda function with
# Runtime Version Python3.7. When integrated with AWS Eventbridge and S3 Bucket. It logs
# changes in EC2 state that has been made through file in S3 bucket
# ------------------------------------------------------------------------------------------------

import json
import boto3
from datetime import datetime

print('Loading function')

s3 = boto3.client('s3')


def lambda_handler(event, context):
    # Checking event data
    print("Received event: " + json.dumps(event, indent=2))

    # creating json object for event
    ec2_event_data_json = json.dumps(event, indent=2)

    # logging respoonse data
    response_data = put_file_to_s3(s3, ec2_event_data_json)
    print(response_data)


def put_file_to_s3(s3, ec2_event_data_json):

    # datetime object containing current date and time
    now = datetime.now()

    # Creating json file from object
    s3_jsonFile_to_upload = open("ec2_state.json", "w")
    s3_jsonFile_to_upload.write(ec2_event_data_json)
    s3_jsonFile_to_upload.close()

    # uploading file to s3 example bucket
    response = s3.put_object(
        Body="ec2_state.json",
        Bucket='examplebucket',
        Key=now,
    )

    print("Successfully uploaded")
    return(response)
