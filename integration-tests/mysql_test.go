package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

const mysqlServiceName = "csb-hcs-mysql"

var _ = Describe("MySQL", Label("mysql"), func() {
	BeforeEach(func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{})).To(Succeed())
	})

	AfterEach(func() {
		Expect(mockTerraform.Reset()).To(Succeed())
	})

	It("should provision with defaults", func() {
		instanceID, err := broker.Provision(mysqlServiceName, "default", map[string]any{
			"storage_gb":         100,
			"availability_zones": []any{"az1"},
			"vpc_id":             "fake-vpc-id",
			"subnet_name":        "subnet-default",
			"security_group_id":  "fake-sg-id",
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("instance_name", "csb-mysql-"+instanceID),
				HaveKeyWithValue("flavor", "rds.mysql.large.4.single"),
				HaveKeyWithValue("mysql_version", "8.0"),
				HaveKeyWithValue("storage_gb", float64(100)),
				HaveKeyWithValue("volume_type", "ULTRAHIGH"),
				HaveKeyWithValue("availability_zones", ConsistOf("az1")),
				HaveKeyWithValue("port", float64(3306)),
				HaveKeyWithValue("vpc_id", "fake-vpc-id"),
				HaveKeyWithValue("subnet_name", "subnet-default"),
				HaveKeyWithValue("security_group_id", "fake-sg-id"),
				HaveKeyWithValue("admin_password", BeNil()),
				HaveKeyWithValue("backup_start_time", "03:00-04:00"),
				HaveKeyWithValue("backup_keep_days", float64(7)),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("cloud", fakeCloud),
				HaveKeyWithValue("labels", MatchKeys(IgnoreExtras, Keys{
					"pcf-instance-id": Equal(instanceID),
				})),
			),
		)
	})

	It("should not allow changing of plan defined properties", func() {
		_, err := broker.Provision(mysqlServiceName, "default", map[string]any{
			"storage_gb":         100,
			"availability_zones": []any{"az1"},
			"vpc_id":             "fake-vpc-id",
			"subnet_name":        "subnet-default",
			"security_group_id":  "fake-sg-id",
			"flavor":             "rds.mysql.xlarge.8.single",
		})

		Expect(err).To(MatchError(ContainSubstring("plan defined properties cannot be changed: flavor")))
	})

	DescribeTable("property constraints",
		func(params map[string]any, expectedErrorMsg string) {
			_, err := broker.Provision(mysqlServiceName, "default", params)

			Expect(err).To(MatchError(ContainSubstring(expectedErrorMsg)))
		},
		Entry(
			"invalid mysql_version",
			map[string]any{
				"storage_gb":         100,
				"availability_zones": []any{"az1"},
				"vpc_id":             "fake-vpc-id",
				"subnet_name":        "subnet-default",
				"security_group_id":  "fake-sg-id",
				"mysql_version":      "5.6",
			},
			"mysql_version must be one of the following",
		),
		Entry(
			"storage_gb below minimum",
			map[string]any{
				"storage_gb":         30,
				"availability_zones": []any{"az1"},
				"vpc_id":             "fake-vpc-id",
				"subnet_name":        "subnet-default",
				"security_group_id":  "fake-sg-id",
			},
			"storage_gb",
		),
		Entry(
			"storage_gb not multiple of 10",
			map[string]any{
				"storage_gb":         55,
				"availability_zones": []any{"az1"},
				"vpc_id":             "fake-vpc-id",
				"subnet_name":        "subnet-default",
				"security_group_id":  "fake-sg-id",
			},
			"storage_gb",
		),
	)

	It("should create a per-binding account on bind", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "instance_id", Type: "string", Value: "fake-rds-id"},
			{Name: "name", Type: "string", Value: "fake-rds-name"},
			{Name: "hostname", Type: "string", Value: "192.168.1.20"},
			{Name: "port", Type: "number", Value: float64(3306)},
			{Name: "username", Type: "string", Value: "root"},
			{Name: "password", Type: "string", Value: "fake-admin-password"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(mysqlServiceName, "default", map[string]any{
			"storage_gb":         100,
			"availability_zones": []any{"az1"},
			"vpc_id":             "fake-vpc-id",
			"subnet_name":        "subnet-default",
			"security_group_id":  "fake-sg-id",
		})
		Expect(err).NotTo(HaveOccurred())

		// The mock has a single TF state: switch it to the bind workspace outputs before binding.
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "username", Type: "string", Value: "appuser"},
			{Name: "password", Type: "string", Value: "fake-binding-password"},
			{Name: "hostname", Type: "string", Value: "192.168.1.20"},
			{Name: "port", Type: "number", Value: float64(3306)},
			{Name: "uri", Type: "string", Value: "mysql://appuser:fake-binding-password@192.168.1.20:3306/"},
			{Name: "jdbcUrl", Type: "string", Value: "jdbc:mysql://192.168.1.20:3306/"},
		})).To(Succeed())

		creds, err := broker.Bind(mysqlServiceName, "default", instanceID, map[string]any{
			"user_name": "appuser",
		})
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(
			SatisfyAll(
				HaveKeyWithValue("username", "appuser"),
				HaveKeyWithValue("hostname", "192.168.1.20"),
				HaveKeyWithValue("port", float64(3306)),
				HaveKeyWithValue("uri", "mysql://appuser:fake-binding-password@192.168.1.20:3306/"),
				HaveKeyWithValue("jdbcUrl", "jdbc:mysql://192.168.1.20:3306/"),
				HaveKeyWithValue("password", "fake-binding-password"),
			),
		)

		vars, err := lastTerraformInvocationVars(mockTerraform)
		Expect(err).NotTo(HaveOccurred())
		Expect(vars).To(
			SatisfyAll(
				HaveKeyWithValue("instance_id", "fake-rds-id"),
				HaveKeyWithValue("user_name", "appuser"),
				HaveKeyWithValue("authorized_hosts", ConsistOf("%")),
				HaveKeyWithValue("hostname", "192.168.1.20"),
				HaveKeyWithValue("port", float64(3306)),
				HaveKeyWithValue("admin_username", "root"),
				HaveKeyWithValue("admin_password", "fake-admin-password"),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("cloud", fakeCloud),
			),
		)
	})
})
