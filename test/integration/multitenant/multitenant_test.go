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

package multitenant

import (
	"fmt"
	"regexp"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"

	"github.com/terraform-google-modules/enterprise-application/test/integration/testutils"
)

func TestMultitenant(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../1-bootstrap"),
	)

	backend_bucket := bootstrap.GetStringOutput("state_bucket")
	backendConfig := map[string]interface{}{
		"bucket": backend_bucket,
	}

	for _, envName := range []string{
		"development",
		"non-production",
		"production",
	} {
		envName := envName
		t.Run(envName, func(t *testing.T) {
			t.Parallel()
			multitenant := tft.NewTFBlueprintTest(t,
				tft.WithTFDir(fmt.Sprintf("../../../2-multitenant/envs/%s", envName)),
				tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
				tft.WithBackendConfig(backendConfig),
			)

			multitenant.DefineVerify(func(assert *assert.Assertions) {
				multitenant.DefaultVerify(assert)

				// Project IDs
				clusterProjectID := multitenant.GetStringOutput("cluster_project_id")
				regions := terraform.OutputList(t, multitenant.GetTFOptions(), "cluster_regions")

				// Projects creation
				for _, projectOutput := range []struct {
					projectId string
					apis      []string
				}{
					{
						projectId: clusterProjectID,
						apis: []string{
							"cloudresourcemanager.googleapis.com",
							"compute.googleapis.com",
							"iam.googleapis.com",
							"serviceusage.googleapis.com",
							"container.googleapis.com",
							"gkehub.googleapis.com",
							"anthos.googleapis.com",
							"compute.googleapis.com",
							"mesh.googleapis.com",
							"multiclusteringress.googleapis.com",
							"multiclusterservicediscovery.googleapis.com",
							"sqladmin.googleapis.com",
							"trafficdirector.googleapis.com",
							"anthosconfigmanagement.googleapis.com",
							"sourcerepo.googleapis.com",
						},
					},
				} {
					prj := gcloud.Runf(t, "projects describe %s", projectOutput.projectId)
					assert.Equal("ACTIVE", prj.Get("lifecycleState").String(), fmt.Sprintf("project %s should be ACTIVE", projectOutput.projectId))

					enabledAPIS := gcloud.Runf(t, "services list --project %s", projectOutput.projectId).Array()
					listApis := testutils.GetResultFieldStrSlice(enabledAPIS, "config.name")
					assert.Subset(listApis, projectOutput.apis, "APIs should have been enabled")
				}

				// GKE Cluster
				clusterIds := terraform.OutputList(t, multitenant.GetTFOptions(), "clusters_ids")
				listMonitoringEnabledComponents := []string{
					"SYSTEM_COMPONENTS",
					"DEPLOYMENT",
				}

				for _, id := range clusterIds {
					// Cluster location
					location := regexp.MustCompile(`\/locations\/([^\/]*)\/`).FindStringSubmatch(id)[1]
					// Cluster and Membership details
					clusterOp := gcloud.Runf(t, "container clusters describe %s --location %s --project %s", id, location, clusterProjectID)
					membershipOp := gcloud.Runf(t, "container fleet memberships describe %s --location %s --project %s", clusterOp.Get("name").String(), location, clusterProjectID)
					// NodePool
					assert.Equal("node-pool-1", clusterOp.Get("nodePools.0.name").String(), "NodePool name should be node-pool-1")
					assert.Equal("SURGE", clusterOp.Get("nodePools.0.upgradeSettings.strategy").String(), "NodePool strategy should SURGE")
					assert.Equal("1", clusterOp.Get("nodePools.0.upgradeSettings.maxSurge").String(), "NodePool max surge should be 1")
					assert.Equal("BALANCED", clusterOp.Get("nodePools.0.autoscaling.locationPolicy").String(), "NodePool auto scaling location prolicy should be BALANCED")
					assert.True(clusterOp.Get("nodePools.0.autoscaling.enabled").Bool(), "NodePool auto scaling should be enabled (true)")
					// Cluster
					assert.Equal(clusterProjectID, clusterOp.Get("fleet.project").String(), fmt.Sprintf("Cluster %s Fleet Project should be %s", id, clusterProjectID))
					clusterEnabledComponents := utils.GetResultStrSlice(clusterOp.Get("monitoringConfig.componentConfig.enableComponents").Array())
					assert.Equal(listMonitoringEnabledComponents, clusterEnabledComponents, fmt.Sprintf("Cluster %s should have Monitoring Enabled Components: SYSTEM_COMPONENTS and DEPLOYMENT", id))
					assert.True(clusterOp.Get("monitoringConfig.managedPrometheusConfig.enabled").Bool(), fmt.Sprintf("Cluster %s should have Managed Prometheus Config equals True", id))
					assert.Equal(fmt.Sprintf("%s.svc.id.goog", clusterProjectID), clusterOp.Get("workloadIdentityConfig.workloadPool").String(), fmt.Sprintf("Cluster %s workloadPool should be %s.svc.id.goog", id, clusterProjectID))
					assert.Equal(fmt.Sprintf("%s.svc.id.goog", clusterProjectID), membershipOp.Get("authority.workloadIdentityPool").String(), fmt.Sprintf("Membership %s workloadIdentityPool should be %s.svc.id.goog", id, clusterProjectID))
				}

				for _, region := range regions {
					// Cloud SQL
					dbName := fmt.Sprintf("db-%s-%s", region, envName)
					dbOp := gcloud.Run(t, fmt.Sprintf("sql instances describe %s --project %s", dbName, clusterProjectID))
					assert.Equal("POSTGRES_14", dbOp.Get("databaseVersion").String(), "Data base installed version should be POSTGRES_14.")
					assert.Equal("db-custom-1-3840", dbOp.Get("settings.tier").String(), "Tier setting should be db-custom-1-3840.")
					assert.Equal("REGIONAL", dbOp.Get("settings.availabilityType").String(), "Availability Type should be REGIONAL.")
				}

				// Bank of Anthos SA
				saName := "bank-of-anthos"
				sqlSAEmail := fmt.Sprintf("%s@%s.iam.gserviceaccount.com", saName, clusterProjectID)
				saOp := gcloud.Run(t, fmt.Sprintf("iam service-accounts describe %s --project %s", sqlSAEmail, clusterProjectID))
				assert.False(saOp.Get("disabled").Bool(), "Service account should not be disabled.")

				sqlSaRoles := []string{
					"roles/cloudsql.client",
					"roles/cloudsql.instanceUser",
				}
				sqlIamFilter := fmt.Sprintf("bindings.members:'serviceAccount:%s'", sqlSAEmail)
				sqlIamCommonArgs := gcloud.WithCommonArgs([]string{"--flatten", "bindings", "--filter", sqlIamFilter, "--format", "json"})
				sqlProjectPolicyOp := gcloud.Run(t, fmt.Sprintf("projects get-iam-policy %s", clusterProjectID), sqlIamCommonArgs).Array()
				sqlSaListRoles := testutils.GetResultFieldStrSlice(sqlProjectPolicyOp, "bindings.role")
				assert.Subset(sqlSaListRoles, sqlSaRoles, fmt.Sprintf("service account %s should have project level roles", sqlSAEmail))

				sqlWorkloadIdentityUsers := []string{
					fmt.Sprintf("serviceAccount:%s.svc.id.goog[accounts-%s/bank-of-anthos]", clusterProjectID, envName),
					fmt.Sprintf("serviceAccount:%s.svc.id.goog[ledger-%s/bank-of-anthos]", clusterProjectID, envName),
				}

				sqlSAIamFilter := "bindings.role:'roles/iam.workloadIdentityUser'"
				sqlSAIamCommonArgs := gcloud.WithCommonArgs([]string{"--flatten", "bindings", "--filter", sqlSAIamFilter, "--format", "json"})
				sqlSAPolicyOp := gcloud.Run(t, fmt.Sprintf("iam service-accounts get-iam-policy %s", sqlSAEmail), sqlSAIamCommonArgs).Array()[0]
				sqlSaListMembers := utils.GetResultStrSlice(sqlSAPolicyOp.Get("bindings.members").Array())
				assert.Subset(sqlSaListMembers, sqlWorkloadIdentityUsers, fmt.Sprintf("service account %s should have workload identity users", sqlSAEmail))
				assert.Equal(len(sqlWorkloadIdentityUsers), len(sqlSaListMembers), fmt.Sprintf("service account % should have %d workload identity users", sqlSAEmail, len(sqlWorkloadIdentityUsers)))

				// Service Identity
				fleetProjectNumber := gcloud.Runf(t, "projects describe %s", clusterProjectID).Get("projectNumber").String()
				gkeServiceAgent := fmt.Sprintf("service-%s@gcp-sa-gkehub.iam.gserviceaccount.com", fleetProjectNumber)
				gkeSaRoles := []string{
					"roles/gkehub.serviceAgent",
				}

				gkeIamFilter := fmt.Sprintf("bindings.members:'serviceAccount:%s'", gkeServiceAgent)
				gkeIamCommonArgs := gcloud.WithCommonArgs([]string{"--flatten", "bindings", "--filter", gkeIamFilter, "--format", "json"})
				gkeProjectPolicyOp := gcloud.Run(t, fmt.Sprintf("projects get-iam-policy %s", clusterProjectID), gkeIamCommonArgs).Array()
				gkeSaListRoles := testutils.GetResultFieldStrSlice(gkeProjectPolicyOp, "bindings.role")
				assert.Subset(gkeSaListRoles, gkeSaRoles, fmt.Sprintf("service account %s should have project level roles", gkeServiceAgent))

				// Endpoints service
				endpointName := fmt.Sprintf("frontend.endpoints.%s.cloud.goog", clusterProjectID)
				endpointOp := gcloud.Run(t, fmt.Sprintf("endpoints services describe %s --project %s", endpointName, clusterProjectID))
				assert.Equal(endpointOp.Get("producerProjectId").String(), clusterProjectID, fmt.Sprintf("Producer Project ID should be %s.", clusterProjectID))

				// Certificate Manager Certificate
				certName := "mcg-cert"
				certOp := gcloud.Run(t, fmt.Sprintf("certificate-manager certificates describe %s --project %s", certName, clusterProjectID))
				assert.Subset(utils.GetResultStrSlice(certOp.Get("managed.domains").Array()), []string{endpointName}, fmt.Sprintf("Managed Domain should contain %s", endpointName))

				// Certificate Manager Certificate Map
				certMapName := "mcg-cert-map"
				certMapOp := gcloud.Run(t, fmt.Sprintf("certificate-manager maps describe %s --project %s", certMapName, clusterProjectID))
				assert.Equal(certMapOp.Get("description").String(), "gateway certificate map", "Certificate Map description should be 'gateway certificate map'.")

				// Certificate Manager Certificate Map Entry
				certMapEntryName := "mcg-cert-map-entry"
				certMapEntryOp := gcloud.Run(t, fmt.Sprintf("certificate-manager maps entries describe %s --map %s --project %s", certMapEntryName, certMapName, clusterProjectID))
				assert.Equal(certMapEntryOp.Get("hostname").String(), endpointName, fmt.Sprintf("Certificate Map Entry hostname should be %s.", endpointName))

				// Cloud Armor
				cloudArmorName := "eab-cloud-armor"
				cloudArmorOp := gcloud.Run(t, fmt.Sprintf("compute security-policies describe %s --project %s --format json", cloudArmorName, clusterProjectID)).Array()[0]
				assert.Equal(cloudArmorOp.Get("description").String(), "EAB Cloud Armor policy", "Cloud Armor description should be EAB Cloud Armor policy.")

				// Compute Addresses
				ipAddressName := "frontend-ip"
				ipOp := gcloud.Run(t, fmt.Sprintf("compute addresses describe %s --project %s --global", ipAddressName, clusterProjectID))
				assert.Equal("EXTERNAL", ipOp.Get("addressType").String(), "External IP type should be EXTERNAL.")

			})

			multitenant.Test()
		})
	}
}
