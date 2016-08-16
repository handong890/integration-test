
import expect from 'expect.js';

import {
  bdd,
  esClient,
  elasticDump
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('discover tab', function describeIndexTests() {
  bdd.before(function () {
    var fromTime = '2015-09-19 06:31:44.000';
    var toTime = '2015-09-23 18:31:44.000';

    PageObjects.common.debug('discover');
    return PageObjects.common.navigateToApp('discover')
    .then(function () {
      PageObjects.common.debug('setAbsoluteRange');
      return PageObjects.header.setAbsoluteRange(fromTime, toTime);
    });
  });

  bdd.describe('field data', function () {
    bdd.it('should initially be expanded', function () {
      PageObjects.common.saveScreenshot('Discover-sidebar-expanded');
      return PageObjects.discover.getSidebarWidth()
        .then(function (width) {
          PageObjects.common.debug('expanded sidebar width = ' + width);
          expect(width > 180).to.be(true);
        });
    });

    bdd.it('should collapse when clicked', function () {
      return PageObjects.discover.toggleSidebarCollapse()
        .then(function () {
          PageObjects.common.saveScreenshot('Discover-sidebar-collapsed');
          PageObjects.common.debug('PageObjects.discover.getSidebarWidth()');
          return PageObjects.discover.getSidebarWidth();
        })
        .then(function (width) {
          PageObjects.common.debug('collapsed sidebar width = ' + width);
          expect(width < 20).to.be(true);
        });
    });

    bdd.it('should expand when clicked', function () {
      return PageObjects.discover.toggleSidebarCollapse()
        .then(function () {
          PageObjects.common.debug('PageObjects.discover.getSidebarWidth()');
          return PageObjects.discover.getSidebarWidth();
        })
        .then(function (width) {
          PageObjects.common.debug('expanded sidebar width = ' + width);
          expect(width > 180).to.be(true);
        });
    });
  });
});
