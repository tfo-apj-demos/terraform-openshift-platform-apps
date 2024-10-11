replicaCount: ${tfe_replica_count}
tls:
  certificateSecret: "tfe-certificate"
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