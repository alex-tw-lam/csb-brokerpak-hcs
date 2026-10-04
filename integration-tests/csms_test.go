package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

const csmsServiceName = "csb-hcs-csms"

var _ = Describe("CSMS", Label("csms"), func() {
	BeforeEach(func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{})).To(Succeed())
	})

	AfterEach(func() {
		Expect(mockTerraform.Reset()).To(Succeed())
	})

	It("should provision with defaults", func() {
		instanceID, err := broker.Provision(csmsServiceName, "default", nil)

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("secret_name", "csb-"+instanceID),
				HaveKeyWithValue("secret_text", BeNil()),
				HaveKeyWithValue("kms_key_id", BeNil()),
				HaveKeyWithValue("description", BeNil()),
				HaveKeyWithValue("region", fakeRegion),
				HaveKeyWithValue("project_name", fakeProjectName),
				HaveKeyWithValue("cloud", fakeCloud),
				HaveKeyWithValue("labels", MatchKeys(IgnoreExtras, Keys{
					"pcf-instance-id": Equal(instanceID),
				})),
			),
		)
	})

	It("should allow a user provided secret value", func() {
		_, err := broker.Provision(csmsServiceName, "default", map[string]any{
			"secret_name": "my-app-secret",
			"secret_text": "super-secret-value",
		})

		Expect(err).NotTo(HaveOccurred())
		Expect(mockTerraform.FirstTerraformInvocationVars()).To(
			SatisfyAll(
				HaveKeyWithValue("secret_name", "my-app-secret"),
				HaveKeyWithValue("secret_text", "super-secret-value"),
			),
		)
	})

	It("should bind by reading back the latest secret version", func() {
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "secret_id", Type: "string", Value: "fake-secret-resource-id/fake-secret-name"},
			{Name: "name", Type: "string", Value: "fake-secret-name"},
			{Name: "latest_version", Type: "string", Value: "v2"},
			{Name: "secret_text", Type: "string", Value: "fake-secret-value"},
			{Name: "region", Type: "string", Value: fakeRegion},
			{Name: "project_name", Type: "string", Value: fakeProjectName},
			{Name: "cloud", Type: "string", Value: fakeCloud},
		})).To(Succeed())

		instanceID, err := broker.Provision(csmsServiceName, "default", nil)
		Expect(err).NotTo(HaveOccurred())

		// The mock has a single TF state: switch it to the bind workspace outputs before binding.
		Expect(mockTerraform.SetTFState([]testframework.TFStateValue{
			{Name: "name", Type: "string", Value: "fake-secret-name"},
			{Name: "value", Type: "string", Value: "fake-secret-value"},
			{Name: "version", Type: "string", Value: "v2"},
		})).To(Succeed())

		creds, err := broker.Bind(csmsServiceName, "default", instanceID, nil)
		Expect(err).NotTo(HaveOccurred())
		Expect(creds).To(
			SatisfyAll(
				HaveKeyWithValue("name", "fake-secret-name"),
				HaveKeyWithValue("value", "fake-secret-value"),
				HaveKeyWithValue("version", "v2"),
			),
		)
	})
})
