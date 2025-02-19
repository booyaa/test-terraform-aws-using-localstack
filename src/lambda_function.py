def lambda_handler(event, context):
    print(f"Lambda successfully triggered by S3 event file uploaded: {event['Records'][0]['s3']['object']['key']}")
