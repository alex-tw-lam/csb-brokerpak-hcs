package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

const dcsServiceName = "csb-hcs-dcs"

var _ = Describe("DCS", Label("dcs"), func() {
	BeforeEach(func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{})).To(Succeed())
	})

	AfterEach(func() {
		Expect(mockTerraform.Reset()).To(Succeed())
	})

	It("should provision with defaults", func() {
		instanceID, err := broker.Provision(dcsServiceName, "small", map[string]any{
			"availability_zone": "az1",
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("instance_name", "csb-dcs-"+instanceID),
				HaveKeyWithValue("flavor", BeNil()),
				HaveKeyWithValue("capacity", float64(0.125)),
				HaveKeyWithValue("cache_mode", "single"),
				HaveKeyWithValue("engine_version", "5.0"),
				HaveKeyWithValue("availability_zone", "az1"),
				HaveKeyWithValue("standby_availability_zone", BeNil()),
				HaveKeyWithValue("vpc_id", fakeVPCID),
				HaveKeyWithValue("subnet_name", fakeSubnetName),
				HaveKeyWithValue("security_group_id", BeNil()),
				HaveKeyWithValue("port", float64(6379)),
				HaveKeyWithValue("password", BeNil()),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("cloud", fakeCloud),
			),
		)
	})

	It("should not allow changing of plan defined properties", func() {
		_, err := broker.Provision(dcsServiceName, "medium", map[string]any{
			"availability_zone": "az1",
			"capacity":          8,
		})

		Expect(err).To(MatchError(ContainSubstring("plan defined properties cannot be changed: capacity")))
	})

	It("should bind by creating a per-binding account with a random password", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "instance_id", Type: "string", Value: "fake-dcs-id"},
			{Name: "name", Type: "string", Value: "fake-dcs-name"},
			{Name: "domain_name", Type: "string", Value: "fake-dcs-domain"},
			{Name: "port", Type: "number", Value: float64(6379)},
			{Name: "password", Type: "string", Value: "fake-redis-password"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(dcsServiceName, "small", map[string]any{
			"availability_zone": "az1",
		})
		Expect(err).NotTo(HaveOccurred())

		// The mock has a single TF state: switch it to the bind workspace outputs before binding.
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "username", Type: "string", Value: "appuser"},
			{Name: "password", Type: "string", Value: "fake-binding-password"},
			{Name: "host", Type: "string", Value: "fake-dcs-domain"},
			{Name: "port", Type: "number", Value: float64(6379)},
			{Name: "uri", Type: "string", Value: "redis://appuser:fake-binding-password@fake-dcs-domain:6379/"},
		})).To(Succeed())

		creds, err := broker.Bind(dcsServiceName, "small", instanceID, map[string]any{
			"account_name": "appuser",
		})
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(
			SatisfyAll(
				HaveKeyWithValue("username", "appuser"),
				HaveKeyWithValue("password", "fake-binding-password"),
				HaveKeyWithValue("host", "fake-dcs-domain"),
				HaveKeyWithValue("port", float64(6379)),
				HaveKeyWithValue("uri", "redis://appuser:fake-binding-password@fake-dcs-domain:6379/"),
			),
		)

		vars, err := lastTerraformInvocationVars(mockTerraform)
		Expect(err).NotTo(HaveOccurred())
		Expect(vars).To(
			SatisfyAll(
				HaveKeyWithValue("instance_id", "fake-dcs-id"),
				HaveKeyWithValue("account_name", "appuser"),
				HaveKeyWithValue("account_role", "write"),
				HaveKeyWithValue("domain_name", "fake-dcs-domain"),
				HaveKeyWithValue("port", float64(6379)),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("cloud", fakeCloud),
			),
		)
	})
})
