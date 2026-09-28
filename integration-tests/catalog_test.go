package integration_test

import (
	testframework "github.com/cloudfoundry/cloud-service-broker/v2/brokerpaktestframework"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
)

var _ = Describe("Catalog", Label("catalog"), func() {
	It("should publish all six HCS services in the catalog", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		services := map[string]string{
			"csb-hcs-ecs":     ecsServiceID,
			"csb-hcs-mysql":   mysqlServiceID,
			"csb-hcs-redis":   redisServiceID,
			"csb-hcs-elb":     elbServiceID,
			"csb-hcs-gaussdb": gaussdbServiceID,
			"csb-hcs-csms":    csmsServiceID,
		}

		for name, id := range services {
			service := testframework.FindService(catalog, name)
			Expect(service.ID).To(Equal(id), "unexpected id for %s", name)
			Expect(service.Tags).To(ContainElement("hcs"), "expected hcs tag for %s", name)
			Expect(service.Metadata.DisplayName).NotTo(BeEmpty(), "expected display name for %s", name)
			Expect(service.Metadata.ImageUrl).To(ContainSubstring("data:image/png;base64,"), "expected inlined image for %s", name)
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

	It("should publish inline plans for the Redis service", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		service := testframework.FindService(catalog, "csb-hcs-redis")
		Expect(service.Plans).To(ConsistOf(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("small"),
				ID:   Equal(redisSmallPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("medium"),
				ID:   Equal(redisMediumPlanID),
			}),
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("large"),
				ID:   Equal(redisLargePlanID),
			}),
		))
	})

	It("should publish environment injected plans for the site-specific services", func() {
		catalog, err := broker.Catalog()
		Expect(err).NotTo(HaveOccurred())

		Expect(testframework.FindService(catalog, "csb-hcs-mysql").Plans).To(ConsistOf(
			MatchFields(IgnoreExtras, Fields{
				Name: Equal("default"),
				ID:   Equal(mysqlCustomPlanID),
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
				Name: Equal("default"),
				ID:   Equal(gaussdbCustomPlanID),
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
