package integration_test

import (
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
	fakeRegion        = "fake-region"
	fakeProjectName   = "fake-project"
	fakeCloud         = "fake.hcs.example.com"
	documentationURL  = "https://doc.hcs.huawei.com/index.html"
	Name              = "Name"
	ID                = "ID"
	csmsServiceID     = "ffd9a343-2ed5-4dfd-a17e-bb3140568b18"
	csmsDefaultPlanID = "712128d0-eb3d-4f5e-a397-7fc71a678d50"
)

var (
	mockTerraform testframework.TerraformMock
	broker        *testframework.TestInstance
)

var _ = BeforeSuite(func() {
	var err error
	mockTerraform, err = testframework.NewTerraformMock()
	Expect(err).NotTo(HaveOccurred())

	broker, err = testframework.BuildTestInstance(testframework.PathToBrokerPack(), mockTerraform, GinkgoWriter)
	Expect(err).NotTo(HaveOccurred())

	Expect(broker.Start(GinkgoWriter, []string{
		"HCS_REGION_NAME=" + fakeRegion,
		"HCS_PROJECT_NAME=" + fakeProjectName,
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
