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

package hub_network

import (
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-application/test/integration/testutils"
)

func TestHubNetwork(t *testing.T) {
	hubNetworkPath := "../../setup/harness/hub_network"
	hubNetwork := tft.NewTFBlueprintTest(t,
		tft.WithTFDir(hubNetworkPath),
	)

	vars := map[string]interface{}{
		"auto_accept_projects_edge": []string{hubNetwork.GetTFSetupStringOutput("seed_project_id")},
	}

	hubNetworkTest := tft.NewTFBlueprintTest(t,
		tft.WithTFDir(hubNetworkPath),
		tft.WithVars(vars),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
		tft.WithParallelism(100),
	)
	hubNetworkTest.Test()

}
