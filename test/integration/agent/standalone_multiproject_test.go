/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package agent

import (
	"fmt"
	"net"
	"os"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
	"github.com/tidwall/gjson"

	"github.com/GoogleCloudPlatform/terraform-google-enterprise-application/test/integration/testutils"
)

func TestStandaloneMultiprojectAgentExample(t *testing.T) {
	// Initialize test harnesses and setup
	setupOutput := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../setup"))
	setupVPCSCOutput := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../setup/vpcsc"))
	loggingBucketPath := "../../setup/harness/logging_bucket"
	loggingBucket := tft.NewTFBlueprintTest(t, tft.WithTFDir(loggingBucketPath))
	gitlabPath := "../../setup/harness/gitlab"
	gitLab := tft.NewTFBlueprintTest(t, tft.WithTFDir(gitlabPath))

	bootstrapProjectID := setupOutput.GetJsonOutput("harness_project_ids").Get("seed").String()
	networkProjectID := setupOutput.GetJsonOutput("harness_project_ids").Get("seed").String()
	clusterProjectID := setupOutput.GetJsonOutput("harness_project_ids").Get("agent").String()
	appAdminProjectID := setupOutput.GetJsonOutput("harness_project_ids").Get("agent").String()
	workloadProjectID := setupOutput.GetJsonOutput("harness_project_ids").Get("agent").String()

	service_perimeter_mode := setupVPCSCOutput.GetStringOutput("service_perimeter_mode")
	service_perimeter_name := setupVPCSCOutput.GetStringOutput("service_perimeter_name")
	access_level_name := setupVPCSCOutput.GetStringOutput("access_level_name")

	serviceAccount := setupOutput.GetJsonOutput("sa_email").Get("agent").String()
	err := os.Setenv("GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", serviceAccount)
	if err != nil {
		t.Fatalf("failed to set GOOGLE_IMPERSONATE_SERVICE_ACCOUNT: %v", err)
	}

	// Stage 0: Bootstrap Test
	bootstrapVars := map[string]interface{}{
		"bootstrap_project_id": bootstrapProjectID,
		"network_project_id":   networkProjectID,
		"cluster_project_id":   clusterProjectID,
		"logging_bucket":       loggingBucket.GetJsonOutput("logging_bucket").Get("agent").String(),
		"bucket_kms_key":       loggingBucket.GetJsonOutput("bucket_kms_key").Get("agent").String(),
		"attestation_kms_key":  loggingBucket.GetJsonOutput("attestation_kms_key").Get("agent").String(),
	}

	bootstrapTest := tft.NewTFBlueprintTest(t,
		tft.WithVars(bootstrapVars),
		tft.WithTFDir("../../../examples/agent/standalone-multiproject/0-bootstrap"),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
	)

	bootstrapTest.DefineVerify(func(assert *assert.Assertions) {
		stateBucket := bootstrapTest.GetStringOutput("tf_state_bucket")
		assert.NotEmpty(stateBucket)
	})
	bootstrapTest.Test()

	// Stage 1: Platform Infra Test
	ncc_config := map[string]interface{}{
		"enable_ncc":        true,
		"hub_uri":           setupOutput.GetStringOutput("ncc_hub_uri"),
		"spoke_group":       setupOutput.GetStringOutput("ncc_group"),
		"spoke_name":        "vpc-spoke-agent-mp",
		"spoke_description": "Spoke for Capital Agent multiproject example",
	}

	platformVars := map[string]interface{}{
		"network_project_id":     networkProjectID,
		"cluster_project_id":     clusterProjectID,
		"service_perimeter_mode": service_perimeter_mode,
		"service_perimeter_name": service_perimeter_name,
		"access_level_name":      access_level_name,
		"logging_bucket":         loggingBucket.GetJsonOutput("logging_bucket").Get("agent").String(),
		"bucket_kms_key":         loggingBucket.GetJsonOutput("bucket_kms_key").Get("agent").String(),
		"attestation_kms_key":    loggingBucket.GetJsonOutput("attestation_kms_key").Get("agent").String(),
		"ncc_config":             ncc_config,
	}

	platformTest := tft.NewTFBlueprintTest(t,
		tft.WithVars(platformVars),
		tft.WithTFDir("../../../examples/agent/standalone-multiproject/1-platform"),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
	)

	platformTest.DefineVerify(func(assert *assert.Assertions) {
		clusterMembershipIds := testutils.GetBptOutputStrSlice(platformTest, "cluster_membership_ids")
		regionPattern := regexp.MustCompile(`locations/([^/]+)/`)

		for _, membershipID := range clusterMembershipIds {
			matches := regionPattern.FindStringSubmatch(membershipID)
			if len(matches) < 2 {
				t.Fatalf("unable to extract region from membership: %s", membershipID)
			}
			region := matches[1]

			// Verify GKE cluster exists and is private
			op := gcloud.Runf(t, "container clusters list --project %s --filter location=%s", clusterProjectID, region)
			assert.True(op.Array()[0].Get("privateClusterConfig.enablePrivateEndpoint").Bool())

			// Verify nodes have private IPs only
			nodeInstanceGroupUrls := op.Array()[0].Get("nodePools.0.instanceGroupUrls").Array()
			for _, instanceGroupURL := range nodeInstanceGroupUrls {
				instanceGroup := strings.Split(instanceGroupURL.String(), "/")
				instanceGroupName := instanceGroup[len(instanceGroup)-1]
				instanceGroupZone := instanceGroup[len(instanceGroup)-3]

				instances := gcloud.Runf(t, "compute instance-groups list-instances %s --project %s --zone %s", instanceGroupName, clusterProjectID, instanceGroupZone)
				for _, instance := range instances.Array() {
					instanceName := strings.Split(instance.Get("instance").String(), "/")[10]
					instanceDetails := gcloud.Runf(t, "compute instances describe %s --project %s --zone %s", instanceName, clusterProjectID, instanceGroupZone)
					natIP := instanceDetails.Get("networkInterfaces.0.accessConfigs.0.natIP").String()
					assert.Equal(net.IP(nil), net.ParseIP(natIP), fmt.Sprintf("Node instance %s should not have a public IP", instanceName))
				}
			}

			// Verify Cloud Armor security policy
			caPolicy := gcloud.Runf(t, "compute security-policies describe eab-ca-policy-%s --project %s", region, networkProjectID)
			assert.Equal(caPolicy.Get("name").String(), fmt.Sprintf("eab-ca-policy-%s", region))
		}

		// Verify NCC Spoke
		spokeOp := gcloud.Runf(t, "network-connectivity spokes describe %s --project %s --location global", "vpc-spoke-agent-mp", networkProjectID)
		assert.Contains(spokeOp.Get("state").String(), "ACTIVE")
	})
	platformTest.Test()

	// Stage 4: App Factory Test
	appFactoryVars := map[string]interface{}{
		"app_admin_project_id": appAdminProjectID,
		"workload_project_id":  workloadProjectID,
		"cluster_project_id":   clusterProjectID,
		"logging_bucket":       loggingBucket.GetJsonOutput("logging_bucket").Get("agent").String(),
		"bucket_kms_key":       loggingBucket.GetJsonOutput("bucket_kms_key").Get("agent").String(),
		"attestation_kms_key":  loggingBucket.GetJsonOutput("attestation_kms_key").Get("agent").String(),
	}

	appFactoryTest := tft.NewTFBlueprintTest(t,
		tft.WithVars(appFactoryVars),
		tft.WithTFDir("../../../examples/agent/standalone-multiproject/4-appfactory"),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
	)

	appFactoryTest.DefineVerify(func(assert *assert.Assertions) {
		appStateBucket := appFactoryTest.GetStringOutput("tf_state_bucket")
		assert.NotEmpty(appStateBucket)
	})
	appFactoryTest.Test()

	// Stage 5: App Infra Test
	appInfraVars := map[string]interface{}{
		"app_admin_project_id":     appAdminProjectID,
		"workload_project_id":      workloadProjectID,
		"cluster_project_id":       clusterProjectID,
		"cluster_membership_ids":   testutils.GetBptOutputStrSlice(platformTest, "cluster_membership_ids"),
		"cluster_service_accounts": testutils.GetBptOutputStrSlice(platformTest, "cluster_service_accounts"),
		"attestor_id":              platformTest.GetStringOutput("attestor_id"),
		"logging_bucket":           loggingBucket.GetJsonOutput("logging_bucket").Get("agent").String(),
		"bucket_kms_key":           loggingBucket.GetJsonOutput("bucket_kms_key").Get("agent").String(),
		"attestation_kms_key":      loggingBucket.GetJsonOutput("attestation_kms_key").Get("agent").String(),
	}

	appInfraTest := tft.NewTFBlueprintTest(t,
		tft.WithVars(appInfraVars),
		tft.WithTFDir("../../../examples/agent/standalone-multiproject/5-appinfra"),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
	)

	appInfraTest.DefineVerify(func(assert *assert.Assertions) {
		gsaEmail := appInfraTest.GetStringOutput("gsa_email")
		assert.NotEmpty(gsaEmail)

		// Verify IAM roles for Vertex AI
		iamPolicy := gcloud.Runf(t, "projects get-iam-policy %s", workloadProjectID)
		hasVertexRole := false
		for _, binding := range iamPolicy.Get("bindings").Array() {
			if binding.Get("role").String() == "roles/aiplatform.user" {
				for _, member := range binding.Get("members").Array() {
					if member.String() == fmt.Sprintf("serviceAccount:%s", gsaEmail) {
						hasVertexRole = true
					}
				}
			}
		}
		assert.True(hasVertexRole, "GSA should have roles/aiplatform.user on workload project")
	})
	appInfraTest.Test()

	_ = gitLab
	_ = gjson.Result{}
}
