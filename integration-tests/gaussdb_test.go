package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

const gaussdbServiceName = "csb-hcs-gaussdb"

var _ = Describe("GaussDB", Label("gaussdb"), func() {
	BeforeEach(func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{})).To(Succeed())
	})

	AfterEach(func() {
		Expect(mockTerraform.Reset()).To(Succeed())
	})

	It("should provision with defaults", func() {
		instanceID, err := broker.Provision(gaussdbServiceName, "default", map[string]any{
			"availability_zones": []any{"az1", "az2", "az3"},
			"volume_size":        480,
			"vpc_id":             "fake-vpc-id",
			"subnet_name":        "subnet-default",
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("instance_name", "csb-gaussdb-"+instanceID),
				HaveKeyWithValue("flavor", "gaussdb.opengauss.ee.m6.2xlarge.x868.ha"),
				HaveKeyWithValue("availability_zones", ConsistOf("az1", "az2", "az3")),
				HaveKeyWithValue("solution", "hcs1"),
				HaveKeyWithValue("ha_mode", "combined"),
				HaveKeyWithValue("ha_consistency", "eventual"),
				HaveKeyWithValue("ha_consistency_protocol", "quorum"),
				HaveKeyWithValue("volume_type", "ULTRAHIGH"),
				HaveKeyWithValue("volume_size", float64(480)),
				HaveKeyWithValue("port", "8000"),
				HaveKeyWithValue("vpc_id", "fake-vpc-id"),
				HaveKeyWithValue("subnet_name", "subnet-default"),
				HaveKeyWithValue("security_group_id", BeNil()),
				HaveKeyWithValue("sharding_num", float64(3)),
				HaveKeyWithValue("coordinator_num", float64(3)),
				HaveKeyWithValue("datastore_version", BeNil()),
				HaveKeyWithValue("backup_start_time", "03:00-04:00"),
				HaveKeyWithValue("backup_keep_days", float64(7)),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("cloud", fakeCloud),
			),
		)
	})

	It("should bind by passing through the administrator credentials", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "instance_id", Type: "string", Value: "fake-gaussdb-id"},
			{Name: "name", Type: "string", Value: "fake-gaussdb-name"},
			{Name: "endpoints", Type: "string", Value: "192.168.1.30:8000,192.168.1.31:8000"},
			{Name: "private_ips", Type: "string", Value: "192.168.1.30,192.168.1.31"},
			{Name: "username", Type: "string", Value: "dbadmin"},
			{Name: "password", Type: "string", Value: "fake-gaussdb-password"},
			{Name: "port", Type: "string", Value: "8000"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(gaussdbServiceName, "default", map[string]any{
			"availability_zones": []any{"az1", "az2", "az3"},
			"volume_size":        480,
			"vpc_id":             "fake-vpc-id",
			"subnet_name":        "subnet-default",
		})
		Expect(err).NotTo(HaveOccurred())

		// The mock has a single TF state: switch it to the bind workspace outputs before binding.
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "username", Type: "string", Value: "dbadmin"},
			{Name: "password", Type: "string", Value: "fake-gaussdb-password"},
			{Name: "endpoints", Type: "array", Value: []any{"192.168.1.30:8000", "192.168.1.31:8000"}},
			{Name: "hostname", Type: "string", Value: "192.168.1.30"},
			{Name: "port", Type: "string", Value: "8000"},
			{Name: "uri", Type: "string", Value: "postgresql://dbadmin:fake-gaussdb-password@192.168.1.30:8000/postgres"},
		})).To(Succeed())

		creds, err := broker.Bind(gaussdbServiceName, "default", instanceID, nil)
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(
			SatisfyAll(
				HaveKeyWithValue("username", "dbadmin"),
				HaveKeyWithValue("password", "fake-gaussdb-password"),
				HaveKeyWithValue("endpoints", ConsistOf("192.168.1.30:8000", "192.168.1.31:8000")),
				HaveKeyWithValue("hostname", "192.168.1.30"),
				HaveKeyWithValue("port", "8000"),
				HaveKeyWithValue("uri", "postgresql://dbadmin:fake-gaussdb-password@192.168.1.30:8000/postgres"),
			),
		)
	})
})
