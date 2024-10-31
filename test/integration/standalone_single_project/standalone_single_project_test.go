/**
 * Copyright 2024 Google LLC
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

// define test package name
package standalone_single_project

import (
	"fmt"
	"net"
	"regexp"
	"strings"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
	"github.com/tidwall/gjson"

	"github.com/terraform-google-modules/enterprise-application/test/integration/testutils"
)

// name the function as Test*
func TestStandaloneSingleProjectExample(t *testing.T) {

	// initialize Terraform test from the Blueprints test framework
	setupOutput := tft.NewTFBlueprintTest(t)
	projectID := setupOutput.GetTFSetupStringOutput("project_id_standalone")

	// wire setup output project_id_standalone to example var.project_id
	standaloneSingleProjT := tft.NewTFBlueprintTest(t, tft.WithVars(map[string]interface{}{"project_id": projectID}))

	// define and write a custom verifier for this test case call the default verify for confirming no additional changes
	standaloneSingleProjT.DefineVerify(func(assert *assert.Assertions) {
		// perform default verification ensuring Terraform reports no additional changes on an applied blueprint
		// standaloneSingleProjT.DefaultVerify(assert)
		clusterMembershipIds := testutils.GetBptOutputStrSlice(standaloneSingleProjT, "cluster_membership_ids")
		clusterType := standaloneSingleProjT.GetStringOutput("cluster_type")
		listMonitoringEnabledComponents := []string{
			"SYSTEM_COMPONENTS",
			"DEPLOYMENT",
		}

		for _, id := range clusterMembershipIds {
			// Membership details
			membershipOp := gcloud.Runf(t, "container fleet memberships describe %s", strings.TrimPrefix(id, "//gkehub.googleapis.com/"))
			// Cluster details
			clusterLocation := regexp.MustCompile(`\/locations\/([^\/]*)\/`).FindStringSubmatch(membershipOp.Get("endpoint.gkeCluster.resourceLink").String())[1]
			clusterName := regexp.MustCompile(`\/clusters\/([^\/]*)$`).FindStringSubmatch(membershipOp.Get("endpoint.gkeCluster.resourceLink").String())[1]
			clusterOp := gcloud.Runf(t, "container clusters describe %s --location %s --project %s", clusterName, clusterLocation, projectID)

			// Extract enablePrivateEndpoint flag value
			enablePrivateEndpoint := clusterOp.Get("privateClusterConfig.enablePrivateEndpoint").Bool()
			assert.True(enablePrivateEndpoint, "The cluster external endpoint must be private.")

			// Validate if all nodes inside node pool does not contain an external NAT IP address
			nodePoolName := clusterOp.Get("nodePools.0.name").String()
			nodeInstances := gcloud.Runf(t, "compute instances list --filter=\"labels.goog-k8s-node-pool-name=%s\" --project=%s", nodePoolName, projectID).Array()
			for _, node := range nodeInstances {
				// retrieve all node network interfaces
				nics := node.Get("networkInterfaces")
				// for each network interface, verify if it using an external natIP
				nics.ForEach((func(key, value gjson.Result) bool {
					assert.Equal(nil, net.ParseIP(value.Get("accessConfigs.0.natIP").String()), "The nodes inside the nodepool should not have external ip addresses.")
					return true // keep iterating
				}))
			}
			// NodePools
			switch clusterType {
			case "STANDARD":
				assert.Equal("node-pool-1", clusterOp.Get("nodePools.0.name").String(), "NodePool name should be node-pool-1")
				assert.Equal("SURGE", clusterOp.Get("nodePools.0.upgradeSettings.strategy").String(), "NodePool strategy should SURGE")
				assert.Equal("1", clusterOp.Get("nodePools.0.upgradeSettings.maxSurge").String(), "NodePool max surge should be 1")
				assert.Equal("BALANCED", clusterOp.Get("nodePools.0.autoscaling.locationPolicy").String(), "NodePool auto scaling location prolicy should be BALANCED")
				assert.True(clusterOp.Get("nodePools.0.autoscaling.enabled").Bool(), "NodePool auto scaling should be enabled (true)")
			case "STANDARD-NAP":
				for _, pool := range clusterOp.Get("nodePools").Array() {
					if pool.Get("name").String() == "node-pool-1" {
						assert.False(pool.Get("autoscaling.autoprovisioned").Bool(), "NodePool autoscaling autoprovisioned should disabled(false)")
					} else if regexp.MustCompile(`^nap-.*`).FindString(pool.Get("name").String()) != "" {
						assert.True(pool.Get("autoscaling.autoprovisioned").Bool(), "NodePool autoscaling autoprovisioned should enabled(true)")
					} else {
						t.Fatalf("Error: unknown node pool: %s", pool.Get("name").String())
					}
					// common to all valid node pools
					assert.True(pool.Get("autoscaling.enabled").Bool(), "NodePool auto scaling should be enabled (true)")
					assert.Equal("SURGE", pool.Get("upgradeSettings.strategy").String(), "NodePool strategy should SURGE")
					assert.Equal("1", pool.Get("upgradeSettings.maxSurge").String(), "NodePool max surge should be 1")
					assert.Equal("BALANCED", pool.Get("autoscaling.locationPolicy").String(), "NodePool auto scaling location prolicy should be BALANCED")
				}
			case "AUTOPILOT":
				// Autopilot manages all nodepools
			default:
				t.Fatalf("Error: unknown cluster type: %s", clusterType)
			}
			// Cluster
			assert.Equal(projectID, clusterOp.Get("fleet.project").String(), fmt.Sprintf("Cluster %s Fleet Project should be %s", id, projectID))
			clusterEnabledComponents := utils.GetResultStrSlice(clusterOp.Get("monitoringConfig.componentConfig.enableComponents").Array())
			if clusterType != "AUTOPILOT" {
				assert.Equal(listMonitoringEnabledComponents, clusterEnabledComponents, fmt.Sprintf("Cluster %s should have Monitoring Enabled Components: SYSTEM_COMPONENTS and DEPLOYMENT", id))
			}
			assert.True(clusterOp.Get("monitoringConfig.managedPrometheusConfig.enabled").Bool(), fmt.Sprintf("Cluster %s should have Managed Prometheus Config equals True", id))
			assert.Equal(fmt.Sprintf("%s.svc.id.goog", projectID), clusterOp.Get("workloadIdentityConfig.workloadPool").String(), fmt.Sprintf("Cluster %s workloadPool should be %s.svc.id.goog", id, projectID))
			assert.Equal(fmt.Sprintf("%s.svc.id.goog", projectID), membershipOp.Get("authority.workloadIdentityPool").String(), fmt.Sprintf("Membership %s workloadIdentityPool should be %s.svc.id.goog", id, projectID))
			assert.Equal("PROJECT_SINGLETON_POLICY_ENFORCE", clusterOp.Get("binaryAuthorization.evaluationMode").String(), fmt.Sprintf("Cluster %s Binary Authorization Evaluation Mode should be PROJECT_SINGLETON_POLICY_ENFORCE", id))

		}

		// Service Identity
		fleetProjectNumber := gcloud.Runf(t, "projects describe %s", projectID).Get("projectNumber").String()
		gkeServiceAgent := fmt.Sprintf("service-%s@gcp-sa-gkehub.iam.gserviceaccount.com", fleetProjectNumber)
		gkeSaRoles := []string{"roles/gkehub.serviceAgent"}

		// If using a seperate fleet project check the cross project SA role
		if projectID != projectID {
			gkeSaRoles = append(gkeSaRoles, "roles/gkehub.crossProjectServiceAgent")
		}

		gkeIamFilter := fmt.Sprintf("bindings.members:'serviceAccount:%s'", gkeServiceAgent)
		gkeIamCommonArgs := gcloud.WithCommonArgs([]string{"--flatten", "bindings", "--filter", gkeIamFilter, "--format", "json"})
		gkeProjectPolicyOp := gcloud.Run(t, fmt.Sprintf("projects get-iam-policy %s", projectID), gkeIamCommonArgs).Array()
		gkeSaListRoles := testutils.GetResultFieldStrSlice(gkeProjectPolicyOp, "bindings.role")
		assert.Subset(gkeSaListRoles, gkeSaRoles, fmt.Sprintf("service account %s should have project level roles", gkeServiceAgent))

		// Cloud Armor
		cloudArmorName := "eab-cloud-armor"
		cloudArmorOp := gcloud.Run(t, fmt.Sprintf("compute security-policies describe %s --project %s --format json", cloudArmorName, projectID)).Array()[0]
		assert.Equal(cloudArmorOp.Get("description").String(), "EAB Cloud Armor policy", "Cloud Armor description should be EAB Cloud Armor policy.")

		cluster_service_accounts := standaloneSingleProjT.GetJsonOutput("cluster_service_accounts").Array()

		assert.Greater(len(cluster_service_accounts), 0, "The terraform output must contain more than 0 service accounts.")
		// create regex to validate service accounts emails
		saRegex := `^[a-zA-Z0-9_+-]+@[a-zA-Z0-9-]+.iam.gserviceaccount.com$`
		for _, sa := range cluster_service_accounts {
			assert.Regexp(saRegex, sa.String(), "The cluster SA value must be a Google Service Account")
		}
	})

	standaloneSingleProjT.DefineTeardown(func(assert *assert.Assertions) {
		// removes firewall rules created by the service but not being deleted.
		firewallRules := gcloud.Runf(t, "compute firewall-rules list  --project %s --filter=\"mcsd\"", projectID).Array()
		for i := range firewallRules {
			gcloud.Runf(t, "compute firewall-rules delete %s --project %s -q", firewallRules[i].Get("name"), projectID)
		}
		standaloneSingleProjT.DefaultTeardown(assert)

	})
	// call the test function to execute the integration test
	standaloneSingleProjT.Test()
}