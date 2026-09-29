package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

var _ = Describe("Catalog", Label("catalog"), func() {
	It("should publish all seven HCS services in the catalog", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		services := map[string]string{
			"csb-hcs-ecs":            ecsServiceID,
			"csb-hcs-rds-postgresql": rdsPostgresServiceID,
			"csb-hcs-dcs":            dcsServiceID,
			"csb-hcs-elb":            elbServiceID,
			"csb-hcs-gaussdb":        gaussdbServiceID,
			"csb-hcs-csms":           csmsServiceID,
			"csb-hcs-obs":            obsServiceID,
		}

		for name, id := range services {
			service := testframework.FindService(catalog, name)
			Expect(service.ID).To(Equal(id), "unexpected id for %s", name)
			Expect(service.Tags).To(ContainElement("hcs"), "expected hcs tag for %s", name)
			Expect(service.Metadata.DisplayName).NotTo(BeEmpty(), "expected display name for %s", name)
		}
	})

	It("should publish inline plans for the ECS service", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		service := testframework.FindService(catalog, "csb-hcs-ecs")
		Expect(service.Plans).To(ConsistOf(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("small"),
				ID:   Equal(ecsSmallPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("medium"),
				ID:   Equal(ecsMediumPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("large"),
				ID:   Equal(ecsLargePlanID),
			}),
		))
	})

	It("should publish the HA plan for the DCS service", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		service := testframework.FindService(catalog, "csb-hcs-dcs")
		Expect(service.Plans).To(ContainElement(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("ha-large"),
				ID:   Equal(dcsHAPlanID),
			}),
		))
	})

	It("should publish inline plans for the DCS service", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		service := testframework.FindService(catalog, "csb-hcs-dcs")
		Expect(service.Plans).To(ConsistOf(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("small"),
				ID:   Equal(dcsSmallPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("medium"),
				ID:   Equal(dcsMediumPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("large"),
				ID:   Equal(dcsLargePlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("ha-large"),
				ID:   Equal(dcsHAPlanID),
			}),
		))
	})

	It("should publish environment injected plans for the ELB service", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		Expect(testframework.FindService(catalog, "csb-hcs-rds-postgresql").Plans).To(ConsistOf(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("small"),
				ID:   Equal(rdsPostgresSmallPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("medium"),
				ID:   Equal(rdsPostgresMediumPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("large"),
				ID:   Equal(rdsPostgresLargePlanID),
			}),
		))
		Expect(testframework.FindService(catalog, "csb-hcs-elb").Plans).To(ConsistOf(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("default"),
				ID:   Equal(elbCustomPlanID),
			}),
		))
		Expect(testframework.FindService(catalog, "csb-hcs-gaussdb").Plans).To(ConsistOf(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("small"),
				ID:   Equal(gaussdbSmallPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("medium"),
				ID:   Equal(gaussdbMediumPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("large"),
				ID:   Equal(gaussdbLargePlanID),
			}),
		))
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
