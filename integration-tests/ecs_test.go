package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

const ecsServiceName = "csb-hcs-ecs"

var _ = Describe("ECS", Label("ecs"), func() {
	BeforeEach(func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{})).To(Succeed())
	})

	AfterEach(func() {
		Expect(mockTerraform.Reset()).To(Succeed())
	})

	It("should provision with defaults", func() {
		instanceID, err := broker.Provision(ecsServiceName, "small", map[string]any{
			"image_name":        "Ubuntu 22.04 server 64bit",
			"availability_zone": "az1",
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("instance_name", "csb-ecs-"+instanceID),
				HaveKeyWithValue("image_name", "Ubuntu 22.04 server 64bit"),
				HaveKeyWithValue("availability_zone", "az1"),
				HaveKeyWithValue("vpc_name", fakeVPCName),
				HaveKeyWithValue("subnet_name", fakeECSSubnetName),
				HaveKeyWithValue("flavor", "s6.large.2"),
				HaveKeyWithValue("cores", float64(2)),
				HaveKeyWithValue("memory_gb", float64(4)),
				HaveKeyWithValue("security_group_name", fakeECSSGName),
				HaveKeyWithValue("admin_pass", BeNil()),
				HaveKeyWithValue("system_disk_type", "business_type_01"),
				HaveKeyWithValue("system_disk_size", float64(40)),
				HaveKeyWithValue("allocate_eip", false),
				HaveKeyWithValue("bandwidth_size", float64(5)),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("project_name", fakeProjectName),
				HaveKeyWithValue("cloud", fakeCloud),
				HaveKeyWithValue("labels", MatchKeys(IgnoreExtras, Keys{
					"pcf-instance-id": Equal(instanceID),
					"key1":            Equal("value1"),
				})),
			),
		)
	})

	It("should allow overriding properties not defined in the plan", func() {
		_, err := broker.Provision(ecsServiceName, "medium", map[string]any{
			"image_name":        "mini_image",
			"availability_zone": "az2.dc1",
			"subnet_name":       "subnet-app",
			"system_disk_size":  100,
			"allocate_eip":      true,
			"bandwidth_size":    10,
			"admin_pass":        "Str0ng!Passw0rd",
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("flavor", "s6.xlarge.2"),
				HaveKeyWithValue("cores", float64(2)),
				HaveKeyWithValue("memory_gb", float64(4)),
				HaveKeyWithValue("system_disk_size", float64(100)),
				HaveKeyWithValue("allocate_eip", true),
				HaveKeyWithValue("bandwidth_size", float64(10)),
				HaveKeyWithValue("admin_pass", "Str0ng!Passw0rd"),
			),
		)
	})

	It("should not allow changing of plan defined properties", func() {
		_, err := broker.Provision(ecsServiceName, "small", map[string]any{
			"image_name":        "mini_image",
			"availability_zone": "az1",
			"flavor":            "s6.2xlarge.2",
		})

		Expect(err).To(MatchError(ContainSubstring("plan defined properties cannot be changed: flavor")))
	})

	DescribeTable("property constraints",
		func(params map[string]any, expectedErrorMsg string) {
			_, err := broker.Provision(ecsServiceName, "small", params)

			Expect(err).To(MatchError(ContainSubstring(expectedErrorMsg)))
		},
		Entry(
			"missing required image_name",
			map[string]any{
				"availability_zone": "az1",
			},
			"image_name",
		),
		Entry(
			"invalid system_disk_size",
			map[string]any{
				"image_name":        "mini_image",
				"availability_zone": "az1",
				"system_disk_size":  0,
			},
			"system_disk_size",
		),
	)

	It("should bind by passing through the instance addresses", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "instance_id", Type: "string", Value: "fake-ecs-id"},
			{Name: "name", Type: "string", Value: "fake-ecs-name"},
			{Name: "private_ip", Type: "string", Value: "192.168.1.10"},
			{Name: "public_ip", Type: "string", Value: ""},
			{Name: "admin_password", Type: "string", Value: "fake-admin-password"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "project_name", Type: "string", Value: fakeProjectName},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(ecsServiceName, "small", map[string]any{
			"image_name":        "mini_image",
			"availability_zone": "az1",
		})
		Expect(err).NotTo(HaveOccurred())

		creds, err := broker.Bind(ecsServiceName, "small", instanceID, nil)
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(
			SatisfyAll(
				HaveKeyWithValue("instance_id", "fake-ecs-id"),
				HaveKeyWithValue("name", "fake-ecs-name"),
				HaveKeyWithValue("private_ip", "192.168.1.10"),
				HaveKeyWithValue("public_ip", ""),
				HaveKeyWithValue("admin_password", "fake-admin-password"),
			),
		)
	})
})
