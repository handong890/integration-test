
import expect from 'expect.js';

import {
  bdd
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('monitoring app', function describeIndexTests() {
  bdd.before(function () {
    PageObjects.common.debug('monitoring');
    return PageObjects.common.navigateToApp('monitoring');
  });


  bdd.describe('main page', function () {

    bdd.it('should show the Welcome message', function () {
      var expectedMessage = 'Don\'t Show Again\nWelcome to Monitoring!\nMonitoring is the part'
        + ' of X-Pack that keeps your Elastic Stack in check and provides actionable insights to help'
        + ' you get the most out of your cluster. It is free to use in both development and production.'
        + '\nSharing your cluster statistics with us helps us improve. Your data is never shared with'
        + ' anyone. Not interested? Opt out here.';
      return PageObjects.monitoring.getWelcome()
      .then(function (actualMessage) {
        expect(actualMessage).to.be(expectedMessage);
      });
    });

    bdd.it('should show Elasticsearch status not red', function () {
      // get the health first and then check the UI
      // http://localhost:9200/_cluster/health

      return PageObjects.monitoring.getElasticsearchSmallPanelStatus()
      .then(function (actualQueryNameString) {
        expect(actualQueryNameString).to.be('status status-yellow');
      });
    });

    bdd.it('should show Nodes: 1', function () {
      return PageObjects.monitoring.getElasticsearchSmallPanelNodeCount()
      .then(function (actualQueryNameString) {
        expect(actualQueryNameString).to.be('1');
      });
    });

    // bdd.it('should show Kibana status Green', function () {
    //   return PageObjects.monitoring.getKibanaSmallPanelStatus()
    //   .then(function () {
    //     return PageObjects.common.sleep(13000);
    //   })
    //   .then(() => {
    //     PageObjects.common.saveScreenshot('Monitoring');
    //   })
    //   .then(function (actualQueryNameString) {
    //     expect(actualQueryNameString).to.be('status status-green');
    //   });
    // });

  });
});
