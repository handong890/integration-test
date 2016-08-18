
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

  bdd.it('In vs Out Network Bytes - should contain at least 3 data points', function () {
    return PageObjects.visualize.openSavedVisualization('In vs Out Network Bytes')
    .then(() => {
      return PageObjects.common.sleep(3000)
    })
    .then(() => {
      return PageObjects.visualize.getLineChartData('data-label="In Bytes"');
    })
    .then(function showData(data) {
      PageObjects.common.saveScreenshot('In vs Out Network Bytes');
      PageObjects.common.debug('Found ' + data.length + ' data points for "In Bytes"');
      expect(data.length > 2).to.be(true);
    });
  });

});
