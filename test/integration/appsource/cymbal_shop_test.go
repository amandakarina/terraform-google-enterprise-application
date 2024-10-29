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

package appsource

import (
	"errors"
	"fmt"
	"slices"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/git"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-google-modules/enterprise-application/test/integration/testutils"

	cp "github.com/otiai10/copy"
)

func TestSourceCymbalShop(t *testing.T) {

	env_cluster_membership_ids := make(map[string]map[string][]string, 0)

	for _, envName := range testutils.EnvNames(t) {
		env_cluster_membership_ids[envName] = make(map[string][]string, 0)
		multitenant := tft.NewTFBlueprintTest(t, tft.WithTFDir(fmt.Sprintf("../../../2-multitenant/envs/%s", envName)))
		env_cluster_membership_ids[envName]["cluster_membership_ids"] = testutils.GetBptOutputStrSlice(multitenant, "cluster_membership_ids")
	}

	region := "us-central1" // TODO: Plumb output from appInfra
	appName := "cymbal-shop"
	serviceName := "cymbalshop"
	appSourcePath := fmt.Sprintf("../../../examples/%s/6-appsource/%s", appName, appName)

	appFactory := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../../4-appfactory/envs/shared"))

	projectID := appFactory.GetJsonOutput("app-group").Get("cymbal-shop\\.cymbalshop.app_admin_project_id").String()

	t.Run("replace-repo-contents-and-push", func(t *testing.T) {

		appRepo := fmt.Sprintf("https://source.developers.google.com/p/%s/r/eab-%s-%s", projectID, appName, serviceName)
		t.Logf("source-repo: %s", appRepo)

		tmpDirApp := t.TempDir()

		vars := map[string]interface{}{
			"project_id":                 projectID,
			"region":                     region,
			"env_cluster_membership_ids": env_cluster_membership_ids,
			"buckets_force_destroy":      "true",
		}

		appsource := tft.NewTFBlueprintTest(t,
			tft.WithTFDir(appSourcePath),
			tft.WithVars(vars),
			tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
		)

		appsource.DefineVerify(func(assert *assert.Assertions) {

			// Push cymbal bank app source code
			gitApp := git.NewCmdConfig(t, git.WithDir(tmpDirApp))
			gitAppRun := func(args ...string) {
				_, err := gitApp.RunCmdE(args...)
				if err != nil {
					t.Fatal(err)
				}
			}

			gitAppRun("clone", "--branch", "v0.10.1", "https://github.com/GoogleCloudPlatform/microservices-demo.git", tmpDirApp)
			gitAppRun("config", "user.email", "eab-robot@example.com")
			gitAppRun("config", "user.name", "EAB Robot")
			gitAppRun("config", "credential.https://source.developers.google.com.helper", "gcloud.sh")
			gitAppRun("config", "init.defaultBranch", "main")
			gitAppRun("config", "http.postBuffer", "157286400")
			gitAppRun("checkout", "-b", "main")
			gitAppRun("remote", "add", "google", appRepo)

			// copy contents from 6-appsource to the cloned repository
			err := cp.Copy(appSourcePath, tmpDirApp)
			if err != nil {
				t.Fatal(err)
			}

			gitAppRun("add", ".")
			gitApp.CommitWithMsg("initial commit", []string{"--allow-empty"})
			gitAppRun("push", "--all", "google", "-f")

			lastCommit := gitApp.GetLatestCommit()
			// filter builds triggered based on pushed commit sha
			buildListCmd := fmt.Sprintf("builds list --region=%s --filter substitutions.COMMIT_SHA='%s' --project %s", region, lastCommit, projectID)
			// poll build until complete
			pollCloudBuild := func(cmd string) func() (bool, error) {
				return func() (bool, error) {
					build := gcloud.Runf(t, cmd).Array()
					if len(build) < 1 {
						return true, nil
					}
					latestWorkflowRunStatus := build[0].Get("status").String()
					if latestWorkflowRunStatus == "SUCCESS" {
						return false, nil
					} else if latestWorkflowRunStatus == "FAILURE" {
						return false, errors.New("Build failed.")
					}
					return true, nil
				}
			}
			utils.Poll(t, pollCloudBuild(buildListCmd), 60, 30*time.Second)
			releaseListCmd := fmt.Sprintf("deploy releases list --project=%s --delivery-pipeline=%s --region=%s --filter=name:%s", projectID, serviceName, region, lastCommit[0:7])
			releases := gcloud.Runf(t, releaseListCmd).Array()
			if len(releases) == 0 {
				t.Fatal("Failed to find the release.")
			}
			releaseName := releases[0].Get("name")
			targetId := fmt.Sprintf("%s-development", region) //TODO: convert to loop using env_cluster_membership_ids
			rolloutListCmd := fmt.Sprintf("deploy rollouts list --project=%s --delivery-pipeline=%s --region=%s --release=%s --filter targetId=%s", projectID, serviceName, region, releaseName, targetId)
			// Poll CD rollouts until rollout is successful
			pollCloudDeploy := func(cmd string) func() (bool, error) {
				return func() (bool, error) {
					rollouts := gcloud.Runf(t, cmd).Array()
					if len(rollouts) < 1 {
						return true, nil
					}
					latestRolloutState := rollouts[0].Get("state").String()
					if latestRolloutState == "SUCCEEDED" {
						return false, nil
					} else if slices.Contains([]string{"IN_PROGRESS", "PENDING_RELEASE"}, latestRolloutState) {
						return true, nil
					} else {
						logsCmd := fmt.Sprintf("logging read --project=%s", projectID)
						logs := gcloud.Runf(t, logsCmd).Array()
						for _, log := range logs {
							t.Logf("%s build-log: %s", serviceName, log.Get("textPayload").String())
						}
						return false, fmt.Errorf("Rollout %s.", latestRolloutState)
					}
				}
			}
			utils.Poll(t, pollCloudDeploy(rolloutListCmd), 40, 60*time.Second)
		})
		appsource.Test()
	})

}