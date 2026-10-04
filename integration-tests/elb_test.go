package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

const elbServiceName = "csb-hcs-elb"

var _ = Describe("ELB", Label("elb"), func() {
	BeforeEach(func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{})).To(Succeed())
	})

	AfterEach(func() {
		Expect(mockTerraform.Reset()).To(Succeed())
	})

	It("should provision with defaults", func() {
		instanceID, err := broker.Provision(elbServiceName, "default", map[string]any{})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("loadbalancer_name", "csb-elb-"+instanceID),
				HaveKeyWithValue("l4_flavor_id", "fake-l4-flavor"),
				HaveKeyWithValue("l7_flavor_id", "fake-l7-flavor"),
				HaveKeyWithValue("vpc_name", fakeVPCName),
				HaveKeyWithValue("subnet_name", fakeELBSubnetName),
				HaveKeyWithValue("ipv4_address", BeNil()),
				HaveKeyWithValue("listener_protocol", "TCP"),
				HaveKeyWithValue("listener_port", float64(80)),
				HaveKeyWithValue("lb_method", "ROUND_ROBIN"),
				HaveKeyWithValue("backend_members", BeEmpty()),
				HaveKeyWithValue("allocate_eip", false),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("project_name", fakeProjectName),
				HaveKeyWithValue("cloud", fakeCloud),
				HaveKeyWithValue("labels", MatchKeys(IgnoreExtras, Keys{
					"pcf-instance-id": Equal(instanceID),
				})),
			),
		)
	})

	It("should accept backend members and an explicit VIP", func() {
		_, err := broker.Provision(elbServiceName, "default", map[string]any{
			"ipv4_address":      "192.168.1.100",
			"listener_protocol": "TCP",
			"listener_port":     443,
			"backend_members": []any{
				map[string]any{"address": "192.168.1.10", "port": 8080},
				map[string]any{"address": "192.168.1.11", "port": 8080},
			},
			"allocate_eip":   true,
			"bandwidth_size": 10,
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("ipv4_address", "192.168.1.100"),
				HaveKeyWithValue("listener_protocol", "TCP"),
				HaveKeyWithValue("listener_port", float64(443)),
				HaveKeyWithValue("backend_members", ConsistOf(
					MatchKeys(IgnoreExtras, Keys{
						"address": Equal("192.168.1.10"),
						"port":    Equal(float64(8080)),
					}),
					MatchKeys(IgnoreExtras, Keys{
						"address": Equal("192.168.1.11"),
						"port":    Equal(float64(8080)),
					}),
				)),
				HaveKeyWithValue("allocate_eip", true),
				HaveKeyWithValue("bandwidth_size", float64(10)),
			),
		)
	})

	It("should register a backend member on bind", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "loadbalancer_id", Type: "string", Value: "fake-elb-id"},
			{Name: "name", Type: "string", Value: "fake-elb-name"},
			{Name: "vip_address", Type: "string", Value: "192.168.1.100"},
			{Name: "public_ip", Type: "string", Value: "100.1.1.1"},
			{Name: "listener_port", Type: "number", Value: float64(80)},
			{Name: "protocol", Type: "string", Value: "TCP"},
			{Name: "pool_id", Type: "string", Value: "fake-pool-id"},
			{Name: "ipv4_subnet_id", Type: "string", Value: "fake-neutron-subnet-id"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "project_name", Type: "string", Value: fakeProjectName},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(elbServiceName, "default", map[string]any{})
		Expect(err).NotTo(HaveOccurred())

		// The mock has a single TF state: switch it to the bind workspace outputs before binding.
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "loadbalancer_id", Type: "string", Value: "fake-elb-id"},
			{Name: "vip_address", Type: "string", Value: "192.168.1.100"},
			{Name: "public_ip", Type: "string", Value: "100.1.1.1"},
			{Name: "listener_port", Type: "number", Value: float64(80)},
			{Name: "protocol", Type: "string", Value: "TCP"},
			{Name: "member_id", Type: "string", Value: "fake-member-id"},
			{Name: "address", Type: "string", Value: "192.168.1.10"},
			{Name: "port", Type: "number", Value: float64(8080)},
		})).To(Succeed())

		creds, err := broker.Bind(elbServiceName, "default", instanceID, map[string]any{
			"address": "192.168.1.10",
			"port":    8080,
		})
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(
			SatisfyAll(
				HaveKeyWithValue("loadbalancer_id", "fake-elb-id"),
				HaveKeyWithValue("vip_address", "192.168.1.100"),
				HaveKeyWithValue("public_ip", "100.1.1.1"),
				HaveKeyWithValue("listener_port", float64(80)),
				HaveKeyWithValue("protocol", "TCP"),
				HaveKeyWithValue("member_id", "fake-member-id"),
				HaveKeyWithValue("address", "192.168.1.10"),
				HaveKeyWithValue("port", float64(8080)),
			),
		)

		vars, err := lastTerraformInvocationVars(mockTerraform)
		Expect(err).NotTo(HaveOccurred())
		Expect(vars).To(
			SatisfyAll(
				HaveKeyWithValue("pool_id", "fake-pool-id"),
				HaveKeyWithValue("ipv4_subnet_id", "fake-neutron-subnet-id"),
				HaveKeyWithValue("address", "192.168.1.10"),
				HaveKeyWithValue("port", float64(8080)),
				HaveKeyWithValue("weight", float64(1)),
				HaveKeyWithValue("enable_health_check", true),
				HaveKeyWithValue("protocol", "TCP"),
			),
		)
	})

	It("should require address and port to bind", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "loadbalancer_id", Type: "string", Value: "fake-elb-id"},
			{Name: "vip_address", Type: "string", Value: "192.168.1.100"},
			{Name: "public_ip", Type: "string", Value: ""},
			{Name: "listener_port", Type: "number", Value: float64(80)},
			{Name: "protocol", Type: "string", Value: "TCP"},
			{Name: "pool_id", Type: "string", Value: "fake-pool-id"},
			{Name: "ipv4_subnet_id", Type: "string", Value: "fake-neutron-subnet-id"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "project_name", Type: "string", Value: fakeProjectName},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(elbServiceName, "default", map[string]any{})
		Expect(err).NotTo(HaveOccurred())

		_, err = broker.Bind(elbServiceName, "default", instanceID, nil)
		Expect(err).To(MatchError(ContainSubstring("address")))
	})
})
