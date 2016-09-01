
import expect from 'expect.js';

import {
  bdd,
  esClient,
  elasticDump
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('reporting app', function describeIndexTests() {
  bdd.before(() => {
    PageObjects.common.debug('discover');
    return PageObjects.common.navigateToApp('discover');
  });

  bdd.describe('query', () => {
    var queryName1 = 'Query # 1';

    bdd.it('save query should show toast message and display query name', () => {
      var expectedSavedQueryMessage = 'Discover: Saved Data Source "' + queryName1 + '"';
      return PageObjects.discover.saveSearch(queryName1)
      .then(() => {
        return PageObjects.header.getToastMessage();
      })
      .then((toastMessage) => {
        PageObjects.common.saveScreenshot('Discover-save-query-toast');
        expect(toastMessage).to.be(expectedSavedQueryMessage);
      })
      .then(() => {
        return PageObjects.header.waitForToastMessageGone();
      })
      .then(() => {
        return PageObjects.discover.getCurrentQueryName();
      })
      .then((actualQueryNameString) => {
        expect(actualQueryNameString).to.be(queryName1);
      });
    });

    bdd.it('should show toast messages when report is queued', () => {
      var reportQueued = 'Reporting: Search generation has been queued. You can track its progress under Management.';
      PageObjects.common.debug('click Reporting button');
      return PageObjects.discover.clickReporting()
      .then(() => {
        PageObjects.common.saveScreenshot('Reporting-step-1');
        PageObjects.common.debug('click Printable PDF');
        return PageObjects.discover.clickPrintablePdf();
      })
      .then(() => {
        PageObjects.common.saveScreenshot('Reporting-step-2');
        return PageObjects.header.getToastMessage();
      })
      .then((message1) => {
        expect(message1).to.be(reportQueued)
        return PageObjects.header.waitForToastMessageGone();
      });
    });

    bdd.it('should show toast messages when report is ready', () => {
      var reportReady = 'Your report for the "' + queryName1 + '" search is ready! Pick it up from Management > Kibana > Reporting'
      PageObjects.common.debug('get Report ready Notification');
      return PageObjects.header.getToastMessage()
      .then((message2) => {
        PageObjects.common.saveScreenshot('Reporting-step-3');
        expect(message2).to.be(reportReady)
        PageObjects.common.debug('click OK in Notification');
        return PageObjects.header.clickToastOK();
      });
    });


    bdd.it('Management - Reporting - should show completed message', () => {
      var reportQueued = 'Reporting: Search generation has been queued. You can track its progress under Management.';
      var reportReady = 'Your report for the "' + queryName1 + '" search is ready! Pick it up from Management > Kibana > Reporting'

      return PageObjects.settings.navigateTo()
      .then(() => {
        return PageObjects.settings.clickKibanaReporting();
      })
      .then(() => {
        return PageObjects.settings.getLatestReportingJob()
      })
      .then((data1) => {
        expect(data1.queryName).to.be(queryName1);
        expect(data1.type).to.be('search');
        expect(data1.username).to.be('elastic');
        expect(data1.status).to.be('completed');
        PageObjects.common.saveScreenshot('Reporting-step-4');
      });
    });

    bdd.it('Management - Reporting - click the button should download the PDF', () => {
      var windowHandles;
      return PageObjects.settings.clickDownloadPdf()
      .then(() => {
        return PageObjects.common.sleep(5000);
      })
      .then(() => {
        return this.remote.getAllWindowHandles();
      })
      .then((handles) => {
        windowHandles = handles;
        this.remote.switchToWindow(windowHandles[1])
      })
      .then(() => {
        this.remote.getCurrentWindowHandle();
      })
      .then(() => {
        PageObjects.common.saveScreenshot('Reporting-PDF');
      })
      .then(() => {
        return this.remote.getCurrentUrl();
      })
      .then((url) => {
        PageObjects.common.debug('URL = ' + url);
        expect(url).to.contain('/jobs/download/');
      });
    });


  });
});
