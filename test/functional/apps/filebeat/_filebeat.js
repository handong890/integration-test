
import expect from 'expect.js';

import {
  bdd,
  remote,
  esClient
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('check filebeat', function describeGraphTests() {
  bdd.before(function () {
    PageObjects.common.debug('navigateToApp visualize');
    return PageObjects.common.navigateToApp('visualize');
  });

  bdd.it('Disk space distribution pie chart - should have at least 3 slices', function () {
    return PageObjects.visualize.openSavedVisualization('Disk space distribution')
    .then(() => {
      return PageObjects.common.sleep(3000)
    })
    .then(() => {
      return PageObjects.visualize.getPieChartData();
    })
    .then((pieData) => {
      PageObjects.common.debug('pieData.length = ' + pieData.length);
      PageObjects.common.saveScreenshot('Disk_space_distribution');
      expect(pieData.length > 2).to.be(true);
    });
  });

});
