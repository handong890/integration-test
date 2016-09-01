
import expect from 'expect.js';

import {
  bdd,
  remote,
  esClient
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('creating a simple graph', function describeGraphTests() {
  bdd.before(function () {
    return PageObjects.settings.createIndexPattern('packetbeat-*')
    .then(() => {
      return PageObjects.common.navigateToApp('graph');
    });
  });

  bdd.it('should show data circles', function () {
    console.log('graph test 1-------------------------');
    return PageObjects.graph.selectIndexPattern('packetbeat-*')
    .then(() => {
      return PageObjects.graph.clickAddField();
    })
    .then(() => {
      return PageObjects.graph.selectField('source.port');
    })
    .then(() => {
      return PageObjects.common.sleep(2000);
    })
    .then(() => {
      return PageObjects.graph.query('9200');
    })
    .then(() => {
      return PageObjects.common.sleep(4000);
    })
    .then(() => {
      PageObjects.common.saveScreenshot('Graph');
    })
    .then(() => {
      return PageObjects.common.sleep(2000);
    })
    .then(() => {
      return PageObjects.graph.getGraphCircleText();
    })
    .then((circles) => {
      PageObjects.common.debug('circle values = ' + circles);
      expect(circles.length > 2).to.be(true);
    });
  });

});
