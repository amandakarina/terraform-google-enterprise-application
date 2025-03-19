applications = {
  "hpc" = {
    // team-a and team-b will have their own infrastructure project
    "hpc-team-a" = {
      create_infra_project = true
      create_admin_project = true
    },
    "hpc-team-b" = {
      create_infra_project = true
      create_admin_project = true
    }
  }
}

cloudbuildv2_repository_config = {
  repo_type = "GITLABv2"
  repositories = {
    hpc-team-a = {
      repository_name = "hpc-team-a-i-r"
      repository_url  = "https://gitlab.com/user/hpc-team-a-i-r.git"
    },
    hpc-team-b = {
      repository_name = "hpc-team-b-i-r"
      repository_url  = "https://gitlab.com/user/hpc-team-b-i-r.git"
    }
  }
  # The Secret ID format is: projects/PROJECT_NUMBER/secrets/SECRET_NAME
  gitlab_authorizer_credential_secret_id      = "REPLACE_WITH_READ_API_SECRET_ID"
  gitlab_read_authorizer_credential_secret_id = "REPLACE_WITH_READ_USER_SECRET_ID"
  gitlab_webhook_secret_id                    = "REPLACE_WITH_WEBHOOK_SECRET_ID"
  # If you are using a self-hosted instance, you may change the URL below accordingly
  gitlab_enterprise_host_uri = "https://gitlab.com"
  secret_project_id          = "REPLACE_WITH_SECRET_PROJECT_ID"
}
