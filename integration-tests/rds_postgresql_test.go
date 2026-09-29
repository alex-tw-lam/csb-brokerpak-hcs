package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

const rdsPostgresServiceName = "csb-hcs-rds-postgresql"

var _ = Describe("RDS for PostgreSQL", Label("rds-postgresql"), func() {
	BeforeEach(func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{})).To(Succeed())
	})

	AfterEach(func() {
		Expect(mockTerraform.Reset()).To(Succeed())
	})

	It("should provision with defaults", func() {
		instanceID, err := broker.Provision(rdsPostgresServiceName, "small", map[string]any{
			"storage_gb":         100,
			"availability_zones": []any{"az1"},
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("instance_name", "csb-rds-postgresql-"+instanceID),
				HaveKeyWithValue("flavor", "rds.pg.n1.large.2"),
				HaveKeyWithValue("pg_version", "12"),
				HaveKeyWithValue("storage_gb", float64(100)),
				HaveKeyWithValue("volume_type", "ULTRAHIGH"),
				HaveKeyWithValue("availability_zones", ConsistOf("az1")),
				HaveKeyWithValue("ha_replication_mode", "async"),
				HaveKeyWithValue("port", float64(5432)),
				HaveKeyWithValue("vpc_id", fakeVPCID),
				HaveKeyWithValue("subnet_name", fakeSubnetName),
				HaveKeyWithValue("security_group_id", fakeSGID),
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
		_, err := broker.Provision(rdsPostgresServiceName, "small", map[string]any{
			"storage_gb":         100,
			"availability_zones": []any{"az1"},
			"flavor":             "rds.pg.n1.xlarge.2.ha",
		})

		Expect(err).To(MatchError(ContainSubstring("plan defined properties cannot be changed: flavor")))
	})

	DescribeTable("property constraints",
		func(params map[string]any, expectedErrorMsg string) {
			_, err := broker.Provision(rdsPostgresServiceName, "small", params)

			Expect(err).To(MatchError(ContainSubstring(expectedErrorMsg)))
		},
		Entry(
			"invalid pg_version",
			map[string]any{
				"storage_gb":         100,
				"availability_zones": []any{"az1"},
				"vpc_id":             "fake-vpc-id",
				"subnet_name":        "subnet-default",
				"security_group_id":  "fake-sg-id",
				"pg_version":         "9.6",
			},
			"pg_version must be one of the following",
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
			"port outside PostgreSQL range",
			map[string]any{
				"storage_gb":         100,
				"availability_zones": []any{"az1"},
				"vpc_id":             "fake-vpc-id",
				"subnet_name":        "subnet-default",
				"security_group_id":  "fake-sg-id",
				"port":               80,
			},
			"port",
		),
	)

	It("should create a per-binding account on bind", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "instance_id", Type: "string", Value: "fake-rds-id"},
			{Name: "name", Type: "string", Value: "fake-rds-name"},
			{Name: "hostname", Type: "string", Value: "192.168.1.20"},
			{Name: "port", Type: "number", Value: float64(5432)},
			{Name: "username", Type: "string", Value: "root"},
			{Name: "password", Type: "string", Value: "fake-admin-password"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(rdsPostgresServiceName, "small", map[string]any{
			"storage_gb":         100,
			"availability_zones": []any{"az1"},
		})
		Expect(err).NotTo(HaveOccurred())

		// The mock has a single TF state: switch it to the bind workspace outputs before binding.
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "username", Type: "string", Value: "appuser"},
			{Name: "password", Type: "string", Value: "fake-binding-password"},
			{Name: "hostname", Type: "string", Value: "192.168.1.20"},
			{Name: "port", Type: "number", Value: float64(5432)},
			{Name: "uri", Type: "string", Value: "postgresql://appuser:fake-binding-password@192.168.1.20:5432/postgres"},
			{Name: "jdbcUrl", Type: "string", Value: "jdbc:postgresql://192.168.1.20:5432/postgres"},
		})).To(Succeed())

		creds, err := broker.Bind(rdsPostgresServiceName, "small", instanceID, map[string]any{
			"user_name": "appuser",
		})
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(
			SatisfyAll(
				HaveKeyWithValue("username", "appuser"),
				HaveKeyWithValue("hostname", "192.168.1.20"),
				HaveKeyWithValue("port", float64(5432)),
				HaveKeyWithValue("uri", "postgresql://appuser:fake-binding-password@192.168.1.20:5432/postgres"),
				HaveKeyWithValue("jdbcUrl", "jdbc:postgresql://192.168.1.20:5432/postgres"),
				HaveKeyWithValue("password", "fake-binding-password"),
			),
		)

		vars, err := lastTerraformInvocationVars(mockTerraform)
		Expect(err).NotTo(HaveOccurred())
		Expect(vars).To(
			SatisfyAll(
				HaveKeyWithValue("instance_id", "fake-rds-id"),
				HaveKeyWithValue("user_name", "appuser"),
				HaveKeyWithValue("hostname", "192.168.1.20"),
				HaveKeyWithValue("port", float64(5432)),
				HaveKeyWithValue("admin_username", "root"),
				HaveKeyWithValue("admin_password", "fake-admin-password"),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("cloud", fakeCloud),
			),
		)
	})
})
