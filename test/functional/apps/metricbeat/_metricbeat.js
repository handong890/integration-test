
import expect from 'expect.js';

import {
  bdd,
  remote,
  esClient
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('check metricbeat', function describeGraphTests() {
  bdd.before(function () {
    PageObjects.common.debug('navigateToApp visualize');
    return PageObjects.common.navigateToApp('visualize');
  });

  bdd.it('CPU usage over time - should contain at least 3 data points', function () {
    return PageObjects.visualize.openSavedVisualization('CPU usage over time')
    .then(() => {
      return PageObjects.common.sleep(3000)
    })
    .then(() => {
      return PageObjects.visualize.getLineChartData('data-label="CPU user space"');
    })
    .then(function showData(data) {
      PageObjects.common.saveScreenshot('CPU_usage_over_time');
      PageObjects.common.debug('Found ' + data.length + ' data points for CPU user space');
      expect(data.length > 2).to.be(true);
    });
  });

});
