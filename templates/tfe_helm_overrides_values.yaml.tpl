replicaCount: ${tfe_replica_count}
tls:
  certificateSecret: "tfe-certificate"
  caCertData: "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNKekNDQWF5Z0F3SUJBZ0lRYm4zYTNieWJtNFJEaE1JR0ZoWlBjVEFLQmdncWhrak9QUVFEQkRCQk1SVXcKRXdZS0NaSW1pWlB5TEdRQkdSWUZiRzlqWVd3eEdUQVhCZ29Ka2lhSmsvSXNaQUVaRmdsb1lYTm9hV052Y25BeApEVEFMQmdOVkJBTVRCSEp2YjNRd0hoY05Nak14TVRJeE1EWXlOakk0V2hjTk1qZ3hNVEl4TURZek5qSTNXakJCCk1SVXdFd1lLQ1pJbWlaUHlMR1FCR1JZRmJHOWpZV3d4R1RBWEJnb0praWFKay9Jc1pBRVpGZ2xvWVhOb2FXTnYKY25BeERUQUxCZ05WQkFNVEJISnZiM1F3ZGpBUUJnY3Foa2pPUFFJQkJnVXJnUVFBSWdOaUFBU0huMFIybnVidQpXaWhzWkF0bysyTmlHcDVhUE85UlU4bENkckZwbjRxNXY3LzE1YzAzck12TFNHYVBXdWVxTGFlZXV3MURHd3VhCjJ6OHFtTkRUQXMxaTE2bzRNWDUzWDdmU2RSNlpxQVFoUWc4a2VONTRGSm9RN1hIOFpjcXVzT2lqYVRCbk1CTUcKQ1NzR0FRUUJnamNVQWdRR0hnUUFRd0JCTUE0R0ExVWREd0VCL3dRRUF3SUJoakFQQmdOVkhSTUJBZjhFQlRBRApBUUgvTUIwR0ExVWREZ1FXQkJTZ05xZkEwaTF4Y2ZJUm1EUGVzNmlaR2JJWGpqQVFCZ2tyQmdFRUFZSTNGUUVFCkF3SUJBREFLQmdncWhrak9QUVFEQkFOcEFEQm1BakVBbFdxMHEreUNJaDhibFVid3VUZ3ZpUzI4UkViMGxTUnkKenJNNyt2RXQvS0Fhcks5bVBQZzdFb3A0TUVpR2hNejlBakVBeDVzdUJ1bmw2TlNMRE1wQVNlU2t6ZEQrUUVsVgpTUmhwVEpxaDFJVzlzK2pBUkJ0VDErU0ppTzNaWFRzN0lOTW0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ=="
image:
 repository: ${tfe_image_repository_url}
 name: ${tfe_image_name}
 tag: ${tfe_image_tag}
openshift:
   enabled: true
env:
  secretRefs:
    - name: tfe-secrets
  variables:
    # TFE config settings
    TFE_HOSTNAME: ${tfe_hostname}

    # Database settings
    TFE_DATABASE_HOST: ${tfe_database_host}
    TFE_DATABASE_NAME: ${tfe_database_name}
    TFE_DATABASE_USER: ${tfe_database_user}
    TFE_DATABASE_PARAMETERS: ${tfe_database_parameters}

    # Object storage settings
    TFE_OBJECT_STORAGE_TYPE: ${tfe_object_storage_type}
    TFE_OBJECT_STORAGE_S3_BUCKET: ${tfe_object_storage_s3_bucket}
    TFE_OBJECT_STORAGE_S3_REGION: ${tfe_object_storage_s3_region}
    TFE_OBJECT_STORAGE_S3_ENDPOINT: ${tfe_object_storage_s3_endpoint}
    TFE_OBJECT_STORAGE_S3_USE_INSTANCE_PROFILE: ${tfe_object_storage_s3_use_instance_profile}
    TFE_OBJECT_STORAGE_S3_ACCESS_KEY_ID: ${tfe_object_storage_s3_access_key_id}
    # Redis settings
    TFE_REDIS_HOST: ${tfe_redis_host}
    TFE_REDIS_USE_AUTH: ${tfe_redis_use_auth}
    TFE_REDIS_USE_TLS: ${tfe_redis_use_tls}
    # add image with Vault CA trust
    TFE_RUN_PIPELINE_IMAGE: srlynch1/tfc-agent:latest
    TFE_RUN_PIPELINE_KUBERNETES_OPEN_SHIFT_ENABLED: true
    TFE_RUN_PIPELINE_KUBERNETES_NAMESPACE: tfe-agents