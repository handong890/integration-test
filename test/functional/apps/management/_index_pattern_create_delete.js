
import expect from 'expect.js';

import {
  bdd,
  remote,
  scenarioManager,
  esClient
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('creating and deleting default index', function describeIndexTests() {
  bdd.before(function () {
    return PageObjects.settings.navigateTo()
    .then(function () {
      return PageObjects.settings.clickExistingData();
    });
  });

  bdd.describe('index pattern creation', function indexPatternCreation() {
    bdd.before(function () {
      return PageObjects.settings.createIndexPattern();
    });

    bdd.it('should have index pattern in page header', function pageHeader() {
      return PageObjects.settings.getIndexPageHeading().getVisibleText()
      .then(function (patternName) {
        PageObjects.common.saveScreenshot('Settings-indices-new-index-pattern');
        expect(patternName).to.be('logstash-*');
      });
    });

    bdd.it('should have index pattern in url', function url() {
      return PageObjects.common.try(function tryingForTime() {
        return remote.getCurrentUrl()
        .then(function (currentUrl) {
          expect(currentUrl).to.contain('logstash-*');
        });
      });
    });

    bdd.it('should have expected table headers', function checkingHeader() {
      return PageObjects.settings.getTableHeader()
      .then(function (headers) {
        PageObjects.common.debug('header.length = ' + headers.length);
        var expectedHeaders = [
          'name',
          'type',
          'format',
          'analyzed',
          'indexed',
          'controls'
        ];

        // 6 name   type  format  analyzed  indexed   controls
        expect(headers.length).to.be(expectedHeaders.length);

        var comparedHeaders = headers.map(function compareHead(header, i) {
          return header.getVisibleText()
          .then(function (text) {
            expect(text).to.be(expectedHeaders[i]);
          });
        });

        return Promise.all(comparedHeaders);
      });
    });

  });
});
