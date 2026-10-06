package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

const obsServiceName = "csb-hcs-obs"

var _ = Describe("OBS", Label("obs"), func() {
	BeforeEach(func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{})).To(Succeed())
	})

	AfterEach(func() {
		Expect(mockTerraform.Reset()).To(Succeed())
	})

	It("should provision with defaults", func() {
		instanceID, err := broker.Provision(obsServiceName, "default", nil)

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("bucket_name", "csb-"+instanceID),
				HaveKeyWithValue("acl", "private"),
				HaveKeyWithValue("storage_class", "STANDARD"),
				HaveKeyWithValue("versioning", false),
				HaveKeyWithValue("encryption", false),
				HaveKeyWithValue("kms_key_id", BeNil()),
				HaveKeyWithValue("enterprise_project_id", BeNil()),
				HaveKeyWithValue("force_destroy", false),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("project_name", fakeProjectName),
				HaveKeyWithValue("cloud", fakeCloud),
				HaveKeyWithValue("labels", MatchKeys(IgnoreExtras, Keys{
					"pcf-instance-id": Equal(instanceID),
				})),
			),
		)
	})

	It("should allow overriding bucket properties", func() {
		_, err := broker.Provision(obsServiceName, "default", map[string]any{
			"bucket_name":   "my-app-bucket",
			"acl":           "public-read",
			"storage_class": "WARM",
			"versioning":    true,
			"encryption":    true,
			"kms_key_id":    "fake-kms-key-id",
			"force_destroy": true,
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("bucket_name", "my-app-bucket"),
				HaveKeyWithValue("acl", "public-read"),
				HaveKeyWithValue("storage_class", "WARM"),
				HaveKeyWithValue("versioning", true),
				HaveKeyWithValue("encryption", true),
				HaveKeyWithValue("kms_key_id", "fake-kms-key-id"),
				HaveKeyWithValue("force_destroy", true),
			),
		)
	})

	DescribeTable("property constraints",
		func(params map[string]any, expectedErrorMsg string) {
			_, err := broker.Provision(obsServiceName, "default", params)

			Expect(err).To(MatchError(ContainSubstring(expectedErrorMsg)))
		},
		Entry(
			"invalid bucket_name characters",
			map[string]any{"bucket_name": "Invalid_Bucket_Name"},
			"bucket_name",
		),
		Entry(
			"bucket_name too short",
			map[string]any{"bucket_name": "ab"},
			"bucket_name",
		),
		Entry(
			"invalid acl",
			map[string]any{"acl": "invalidValue"},
			"acl must be one of the following",
		),
		Entry(
			"invalid storage_class",
			map[string]any{"storage_class": "DEEP_ARCHIVE"},
			"storage_class must be one of the following",
		),
	)

	It("should bind by passing through the bucket connection details", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "bucket_name", Type: "string", Value: "fake-bucket"},
			{Name: "bucket_domain_name", Type: "string", Value: "fake-bucket.obs.fake.hcs.example.com"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "project_name", Type: "string", Value: fakeProjectName},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(obsServiceName, "default", nil)
		Expect(err).NotTo(HaveOccurred())

		// The mock has a single TF state: switch it to the bind workspace outputs before binding.
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "bucket_name", Type: "string", Value: "fake-bucket"},
			{Name: "bucket_domain_name", Type: "string", Value: "fake-bucket.obs.fake.hcs.example.com"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "project_name", Type: "string", Value: fakeProjectName},
			{Name: "granted", Type: "bool", Value: false},
		})).To(Succeed())

		creds, err := broker.Bind(obsServiceName, "default", instanceID, nil)
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(
			SatisfyAll(
				HaveKeyWithValue("bucket_name", "fake-bucket"),
				HaveKeyWithValue("bucket_domain_name", "fake-bucket.obs.fake.hcs.example.com"),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("project_name", fakeProjectName),
				HaveKeyWithValue("granted", false),
			),
		)

		vars, err := lastTerraformInvocationVars(mockTerraform)
		Expect(err).NotTo(HaveOccurred())
		Expect(vars).To(
			SatisfyAll(
				HaveKeyWithValue("bucket_name", "fake-bucket"),
				HaveKeyWithValue("grant_principal", BeNil()),
				HaveKeyWithValue("grant_permission", "read-write"),
			),
		)
	})

	It("should attach a bucket policy when a grant principal is set", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "bucket_name", Type: "string", Value: "fake-bucket"},
			{Name: "bucket_domain_name", Type: "string", Value: "fake-bucket.obs.fake.hcs.example.com"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "project_name", Type: "string", Value: fakeProjectName},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(obsServiceName, "default", nil)
		Expect(err).NotTo(HaveOccurred())

		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "bucket_name", Type: "string", Value: "fake-bucket"},
			{Name: "bucket_domain_name", Type: "string", Value: "fake-bucket.obs.fake.hcs.example.com"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "project_name", Type: "string", Value: fakeProjectName},
			{Name: "granted", Type: "bool", Value: true},
		})).To(Succeed())

		creds, err := broker.Bind(obsServiceName, "default", instanceID, map[string]any{
			"grant_principal":  "domain/fake-account-id:user/fake-user",
			"grant_permission": "read",
		})
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(HaveKeyWithValue("granted", true))

		vars, err := lastTerraformInvocationVars(mockTerraform)
		Expect(err).NotTo(HaveOccurred())
		Expect(vars).To(
			SatisfyAll(
				HaveKeyWithValue("grant_principal", "domain/fake-account-id:user/fake-user"),
				HaveKeyWithValue("grant_permission", "read"),
			),
		)
	})
})
