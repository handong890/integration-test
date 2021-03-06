
import {
  defaultFindTimeout,
} from '../';

export default class MonitoringPage {

  init(remote) {
    this.remote = remote;
    this.findTimeout = this.remote.setFindTimeout(defaultFindTimeout);
  }

  getWelcome() {
    return this.findTimeout
    .findDisplayedByCssSelector('render-directive')
    .getVisibleText();
  }

  dismissWelcome() {
    return this.findTimeout
    .findDisplayedByCssSelector('button.btn-banner')
    .click();
  }

  // need better test selectors for Monitoring
  // https://github.com/elastic/x-plugins/issues/2758

  getElasticsearchSmallPanelStatus() {
    return this.findTimeout
    //#kibana-body > div > div > div > div.application.ng-scope.tab-overview > div >
    //  monitoring-main > div > div > monitoring-cluster-overview > div > div:nth-child(1) >
    // div > div > div.statusContainer > span.status.status-yellow > span:nth-child(1)

    // #kibana-body > div > div > div > div.application.ng-scope.tab-overview > div >
    //  monitoring-main > div > div > monitoring-cluster-overview > div > div:nth-child(2) >
    // div > div > div > span.status.status-green > span:nth-child(1)

    // #kibana-body > div > div > div > div.application.ng-scope.tab-overview > div >
    // monitoring-main > div > div > monitoring-cluster-overview > div > div:nth-child(1) >
    // div > div > div.statusContainer > span.status.status-yellow
    .findDisplayedByCssSelector('#kibana-body > div > div > div > div.application.ng-scope.tab-overview > div > monitoring-main > div > div > monitoring-cluster-overview > div > div:nth-child(1) > div > div > div.statusContainer > span.status')
    //.getVisibleText();
    .getAttribute('class');
  }

  getKibanaSmallPanelStatus() {
    return this.findTimeout
    .findDisplayedByCssSelector('span.status[data-reactid=".0.1.0.1.0.0"]')
    //.getVisibleText();         #kibana-body > div > div > div > div.application.ng-scope.tab-overview > div > monitoring-main > div > div > monitoring-cluster-overview > div > div:nth-child(2) > div > div > div.statusContainer > span.status.status-green
    .getAttribute('class');
  }

  getElasticsearchSmallPanelUptime() {
    return this.findTimeout
    .findDisplayedByCssSelector('div.statusContainer > span.status')
    .getVisibleText();
  }

  getElasticsearchSmallPanelNodeCount() {
    return this.findTimeout
    .findDisplayedByCssSelector('#kibana-body > div > div > div > div.application.ng-scope.tab-overview > div > monitoring-main > div > div > monitoring-cluster-overview > div > div:nth-child(1) > div > div > div.row > div:nth-child(2) > dl > dt > a > span:nth-child(2)')
    .getVisibleText();
  }

}
