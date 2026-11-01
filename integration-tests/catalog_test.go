package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

var _ = Describe("Catalog", Label("catalog"), func() {
	It("should publish the CSMS service in the catalog", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		service := testframework.FindService(catalog, "csb-hcs-csms")
		Expect(service.ID).To(Equal(csmsServiceID))
		Expect(service.Tags).To(ContainElement("hcs"))
		Expect(service.Metadata.DisplayName).NotTo(BeEmpty())
	})

	It("should publish the default plan for the CSMS service", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		service := testframework.FindService(catalog, "csb-hcs-csms")
		Expect(service.Plans).To(ConsistOf(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("default"),
				ID:   Equal(csmsDefaultPlanID),
			}),
		))
	})
})
