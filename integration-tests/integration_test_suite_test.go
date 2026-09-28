package integration_test

import (
	"encoding/json"
	"fmt"
	"testing"

	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

func TestIntegrationTests(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "IntegrationTests Suite")
}

const (
	fakeRegion          = "fake-region"
	fakeCloud           = "fake.hcs.example.com"
	documentationURL    = "https://doc.hcs.huawei.com/index.html"
	Name                = "Name"
	ID                  = "ID"
	ecsServiceID        = "be7bfe87-da52-4ebe-b446-df08b0345211"
	mysqlServiceID      = "e10ce773-dcde-46c6-809f-640ededdc48c"
	redisServiceID      = "b23276b5-f48a-4562-b4d1-5606ad0e63d8"
	elbServiceID        = "3e6f427f-228d-4bd8-a1a1-ffc25acf6edf"
	gaussdbServiceID    = "a48c4633-3397-4895-9caf-36690a12a368"
	csmsServiceID       = "ffd9a343-2ed5-4dfd-a17e-bb3140568b18"
	ecsSmallPlanID      = "3976af96-a073-4e2d-a6a9-0b9099e7f980"
	ecsMediumPlanID     = "314b5107-29b3-4ecc-a3f6-55092ff0525a"
	ecsLargePlanID      = "a431b59b-b905-4b91-a75e-5e596c7e4732"
	redisSmallPlanID    = "ffaad285-a8d5-41b1-a59c-0f79aacb6f4c"
	redisMediumPlanID   = "dec64db5-f73e-4869-952e-acf615b3cf0f"
	redisLargePlanID    = "7467e48d-677b-4d61-8bfe-6959803d3533"
	csmsDefaultPlanID   = "712128d0-eb3d-4f5e-a397-7fc71a678d50"
	mysqlCustomPlanID   = "d5b301c3-1505-47dc-9a26-508c8e82a2ce"
	elbCustomPlanID     = "1d1c9366-6f51-4f51-8eb0-6a1a29f36c1e"
	gaussdbCustomPlanID = "6d3b9c58-8dd9-4fa3-a21b-6e7a8a2f19f5"
)

var (
	mockTerraform testframework.TerraformMock
	broker        *testframework.TestInstance
)

var customMySQLPlans = []map[string]any{
	{
		"name":        "default",
		"id":          mysqlCustomPlanID,
		"description": "custom MySQL plan defined by customer",
		"metadata": map[string]any{
			"displayName": "custom MySQL service",
		},
		"flavor": "rds.mysql.large.4.single",
	},
}

var customELBPlans = []map[string]any{
	{
		"name":        "default",
		"id":          elbCustomPlanID,
		"description": "custom ELB plan defined by customer",
		"metadata": map[string]any{
			"displayName": "custom ELB service",
		},
		"l4_flavor_id": "fake-l4-flavor",
		"l7_flavor_id": "fake-l7-flavor",
	},
}

var customGaussDBPlans = []map[string]any{
	{
		"name":        "default",
		"id":          gaussdbCustomPlanID,
		"description": "custom GaussDB plan defined by customer",
		"metadata": map[string]any{
			"displayName": "custom GaussDB service",
		},
		"flavor": "gaussdb.opengauss.ee.m6.2xlarge.x868.ha",
	},
}

var _ = BeforeSuite(func() {
	var err error
	mockTerraform, err = testframework.NewTerraformMock()
	Expect(err).NotTo(HaveOccurred())

	broker, err = testframework.BuildTestInstance(testframework.PathToBrokerPack(), mockTerraform, GinkgoWriter, "service-images")
	Expect(err).NotTo(HaveOccurred())

	Expect(broker.Start(GinkgoWriter, []string{
		"GSB_SERVICE_CSB_HCS_MYSQL_PLANS=" + marshall(customMySQLPlans),
		"GSB_SERVICE_CSB_HCS_ELB_PLANS=" + marshall(customELBPlans),
		"GSB_SERVICE_CSB_HCS_GAUSSDB_PLANS=" + marshall(customGaussDBPlans),
		"HCS_REGION_NAME=" + fakeRegion,
		"HCS_CLOUD=" + fakeCloud,
		"HCS_ACCESS_KEY=fake-access-key",
		"HCS_SECRET_KEY=fake-secret-key",
		"CSB_LISTENER_HOST=localhost",
		`GSB_BROKERPAK_CONFIG={"global_labels":[{"key":  "key1", "value":  "value1"},{"key":  "key2", "value":  "value2"}]}`,
	})).To(Succeed())
})

var _ = AfterSuite(func() {
	if broker != nil {
		Expect(broker.Cleanup()).To(Succeed())
	}
})

func marshall(element any) string {
	b, err := json.Marshal(element)
	Expect(err).NotTo(HaveOccurred())
	return string(b)
}

func lastTerraformInvocationVars(p testframework.TerraformMock) (map[string]any, error) {
	invocations, err := p.ApplyInvocations()
	if err != nil {
		return nil, err
	}
	if len(invocations) == 0 {
		return nil, fmt.Errorf("no terraform invocations recorded")
	}

	vars, err := invocations[len(invocations)-1].TFVars()
	if err != nil {
		return nil, err
	}
	return vars, nil
}
