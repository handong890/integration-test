
import expect from 'expect.js';

import {
  bdd,
  remote,
  esClient
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('check packetbeat', function describeGraphTests() {
  bdd.before(function () {
    PageObjects.common.debug('navigateToApp visualize');
    return PageObjects.common.navigateToApp('visualize');
  });

  bdd.it('Latency histogram - should contain at least 3 data points', function () {
    return PageObjects.visualize.openSavedVisualization('Latency histogram')
    .then(() => {
      return PageObjects.common.sleep(3000)
    })
    .then(() => {
      return PageObjects.visualize.getLineChartData('data-label="Count"');
    })
    .then(function showData(data) {
      PageObjects.common.saveScreenshot('Latency_histogram');
      PageObjects.common.debug('Found ' + data.length + ' data points for "Latency histogram"');
      expect(data.length > 2).to.be(true);
    });
  });

});
