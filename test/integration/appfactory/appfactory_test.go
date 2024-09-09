// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package appfactory

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/tidwall/gjson"

	"github.com/terraform-google-modules/enterprise-application/test/integration/testutils"
)

func TestAppfactory(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../1-bootstrap"),
	)

	backend_bucket := bootstrap.GetStringOutput("state_bucket")
	backendConfig := map[string]interface{}{
		"bucket": backend_bucket,
	}

	vars := map[string]interface{}{
		"remote_state_bucket":  backend_bucket,
		"bucket_force_destroy": "true",
	}

	for _, appGroupName := range testutils.AppNames {
		appGroupName := appGroupName
		t.Run(appGroupName, func(t *testing.T) {
			t.Parallel()

			appFactory := tft.NewTFBlueprintTest(t,
				tft.WithTFDir(fmt.Sprintf("../../../4-appfactory/apps/%s", appGroupName)),
				tft.WithVars(vars),
				tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
				tft.WithBackendConfig(backendConfig),
			)

			appFactory.DefineVerify(func(assert *assert.Assertions) {
				appFactory.DefaultVerify(assert)

				// retrieve all cluster service accounts from all multitenant environments
				var allClusterServiceAccounts []string

				for _, envName := range testutils.EnvNames {
					multitenant := tft.NewTFBlueprintTest(t,
						tft.WithTFDir(fmt.Sprintf("../../../2-multitenant/envs/%s", envName)),
					)
					// add to slice the environment service accounts
					for _, sa := range multitenant.GetJsonOutput("cluster_service_accounts").Array() {
						allClusterServiceAccounts = append(allClusterServiceAccounts, ("serviceAccount:" + sa.String()))
					}
				}

				assert.Greater(len(allClusterServiceAccounts), 0, "The slice of cluster service accounts must contain more than 0 service accounts.")

				// check if created folders contain artifactregistry.reader for the cluster service accounts
				// this is necessary to ensure the cluster can download docker images
				for _, folderId := range appFactory.GetJsonOutput("app-folders-ids").Map() {
					t.Run(folderId.String(), func(t *testing.T) {
						t.Parallel()
						folderIamPolicy := gcloud.Runf(t, "resource-manager folders get-iam-policy %s", folderId.String())
						// ensure cluster sa is in folder iam policy for artifactregistry.reader role
						for _, binding := range folderIamPolicy.Get("bindings").Array() {
							if binding.Get("role").String() == "roles/artifactregistry.reader" {
								folderIamPolicyMembers := binding.Get("members").Array()
								for _, sa := range allClusterServiceAccounts {
									assert.True(testutils.Contains(folderIamPolicyMembers, sa), fmt.Sprintf("The cluster service account %s must exist in the folder %s artifactregistry.reader iam policy", sa, folderId))
								}
							}
						}
					})
				}

				// check admin projects
				// TODO: Update to use https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/pull/2356 when released.
				// terraform.OutputJson OK to use as long as there is only one appGroupName
				for applicationService, appData := range gjson.Parse(terraform.OutputJson(t, appFactory.GetTFOptions(), "app-group")).Map() {
					parts := strings.Split(applicationService, ".")
					assert.Equal(len(parts), 2, "The keys of app-group output must be in the format 'app-name'.'service-name', for example: 'cymbal-bank.userservice'")
					appName := parts[0]
					serviceName := parts[1]

					appData := appData
					t.Run(fmt.Sprintf("%s.%s", appName, serviceName), func(t *testing.T) {
						t.Parallel()

						adminProjectID := appData.Get("app_admin_project_id").String()
						adminProjectApis := []string{
							"iam.googleapis.com",
							"cloudresourcemanager.googleapis.com",
							"cloudbuild.googleapis.com",
							"secretmanager.googleapis.com",
							"serviceusage.googleapis.com",
							"cloudbilling.googleapis.com",
							"cloudfunctions.googleapis.com",
							"apikeys.googleapis.com",
							"sourcerepo.googleapis.com",
						}

						prj := gcloud.Runf(t, "projects describe %s", adminProjectID)
						assert.Equal("ACTIVE", prj.Get("lifecycleState").String(), fmt.Sprintf("project %s should be ACTIVE", adminProjectID))

						enabledAPIS := gcloud.Runf(t, "services list --project %s", adminProjectID).Array()
						listApis := testutils.GetResultFieldStrSlice(enabledAPIS, "config.name")
						assert.Subset(listApis, adminProjectApis, "APIs should have been enabled")

						// check app infra repo
						repositoryName := appData.Get("app_infra_repository_name").String()
						repoURL := fmt.Sprintf("https://source.developers.google.com/p/%s/r/%s", adminProjectID, repositoryName)
						repoOP := gcloud.Runf(t, "source repos describe %s --project %s", repositoryName, adminProjectID)
						assert.Equal(repoURL, repoOP.Get("url").String(), "source repo %s should have url %s", repositoryName, repoURL)

						// check workspace SA access to repo
						repoSa := fmt.Sprintf("serviceAccount:tf-cb-%s@%s.iam.gserviceaccount.com", repositoryName, adminProjectID)
						repoIamOpts := gcloud.WithCommonArgs([]string{"--flatten", "bindings", "--filter", "bindings.role:roles/viewer", "--format", "json"})
						repoIamPolicyOp := gcloud.Run(t, fmt.Sprintf("source repos get-iam-policy %s --project %s", repositoryName, adminProjectID), repoIamOpts).Array()[0]
						listMembers := utils.GetResultStrSlice(repoIamPolicyOp.Get("bindings.members").Array())
						assert.Contains(listMembers, repoSa, fmt.Sprintf("Service Account %s should have role roles/viewer on repo %s", repoSa, repositoryName))

						// check cloudbuild workspace
						// buckets
						gcloudArgsBucket := gcloud.WithCommonArgs([]string{"--project", adminProjectID, "--json"})
						for _, bucket := range []struct {
							output string
							suffix string
							prefix string
						}{
							{
								output: "app_cloudbuild_workspace_state_bucket_name",
								suffix: "state",
								prefix: "bkt",
							},
							{
								output: "app_cloudbuild_workspace_logs_bucket_name",
								suffix: "logs",
								prefix: "bkt",
							},
							{
								output: "app_cloudbuild_workspace_artifacts_bucket_name",
								suffix: "build",
								prefix: "bkt",
							},
						} {
							bucketSelfLink := appData.Get(bucket.output).String()
							opBucket := gcloud.Run(t, fmt.Sprintf("storage ls --buckets gs://%s-%s-%s-%s", bucket.prefix, adminProjectID, serviceName, bucket.suffix), gcloudArgsBucket).Array()
							assert.Equal(bucketSelfLink, opBucket[0].Get("metadata.selfLink").String(), fmt.Sprintf("The bucket SelfLink should be %s.", bucketSelfLink))
						}
						// triggers
						repoName := appData.Get("app_infra_repository_name").String()
						for _, trigger := range []struct {
							output string
							file   string
						}{
							{
								output: "app_cloudbuild_workspace_apply_trigger_id",
								file:   "cloudbuild-tf-apply.yaml",
							},
							{
								output: "app_cloudbuild_workspace_plan_trigger_id",
								file:   "cloudbuild-tf-plan.yaml",
							},
						} {
							triggerID := testutils.GetLastSplitElement(appData.Get(trigger.output).String(), "/")
							buildTrigger := gcloud.Runf(t, "builds triggers describe %s --project %s --region %s", triggerID, adminProjectID, "global")
							filename := buildTrigger.Get("filename").String()
							assert.Equal(trigger.file, filename, fmt.Sprintf("The filename for the trigger should be %s but got %s.", trigger.file, filename))
							assert.Equal(repoName, buildTrigger.Get("triggerTemplate.repoName").String(), "the trigger should use the repo %s", repoName)
						}

						// check env projects
						cloudBuildSARoles := []string{"roles/owner"}
						envProjectsIDs := appData.Get("app_env_project_ids")
						envProjectApis := []string{
							"iam.googleapis.com",
							"cloudresourcemanager.googleapis.com",
							"serviceusage.googleapis.com",
							"cloudbilling.googleapis.com",
						}
						branchName := utils.ValFromEnv(t, "TF_VAR_branch_name")
						for _, envName := range testutils.EnvNames(branchName) {
							envProjectID := envProjectsIDs.Get(envName).String()

							envPrj := gcloud.Runf(t, "projects describe %s", envProjectID)
							assert.Equal("ACTIVE", envPrj.Get("lifecycleState").String(), fmt.Sprintf("project %s should be ACTIVE", envProjectID))

							enabledAPIS := gcloud.Runf(t, "services list --project %s", envProjectID).Array()
							listApis := testutils.GetResultFieldStrSlice(enabledAPIS, "config.name")
							assert.Subset(listApis, envProjectApis, "APIs should have been enabled")

							for _, role := range cloudBuildSARoles {
								iamOpts := gcloud.WithCommonArgs([]string{"--flatten", "bindings", "--filter", fmt.Sprintf("bindings.role:%s", role), "--format", "json"})
								iamPolicy := gcloud.Run(t, fmt.Sprintf("projects get-iam-policy %s", envProjectID), iamOpts).Array()[0]
								listMembers := utils.GetResultStrSlice(iamPolicy.Get("bindings.members").Array())
								assert.Contains(listMembers, repoSa, fmt.Sprintf("Service Account %s should have role %s on project %s", repoSa, role, envProjectID))
							}
						}
					})
				}
			})
			appFactory.Test()
		})
	}
}
