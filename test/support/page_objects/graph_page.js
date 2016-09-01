
import {
  defaultFindTimeout,
} from '../';

import PageObjects from './';

export default class GraphPage {

  init(remote) {
    this.remote = remote;
    this.findTimeout = this.remote.setFindTimeout(defaultFindTimeout);
  }


  selectIndexPattern(pattern) {
    return this.findTimeout
    .findDisplayedByCssSelector('.indexDropDown')
    .click()
    .then(() => {
      return this.findTimeout
      .findByCssSelector('.indexDropDown > option[label="' + pattern + '"]')
      .click()
    })
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }

  clickAddField() {
    return this.findTimeout
    .findById('addVertexFieldButton')
    .click()
  }

  selectField(field) {
    return this.findTimeout
    .findDisplayedByCssSelector('select[id="fieldList"] > option[label="' + field + '"]')
    .click()
    .then(() => {
      return this.findTimeout
      .findDisplayedByCssSelector('button[ng-click="addFieldToSelection()"]')
      .click()
    })
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }

  query(str) {
    return this.findTimeout
    .findDisplayedById('basicSearchInputQuery')
    .type(str)
    .then(() => {
      return this.findTimeout
      .findByCssSelector('button[aria-label="Search"]')
      .click();
    })
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }


  getGraphCircleText() {
    return this.remote
    .setFindTimeout(defaultFindTimeout)
    .findAllByCssSelector('#svgRootGroup > g > text')
    .then(function (chartTypes) {

      function getChartType(circle) {
        return circle
        .getVisibleText();
      }

      var getChartTypesPromises = chartTypes.map(getChartType);
      return Promise.all(getChartTypesPromises);
    })
    .then(function (circleText) {
      return circleText;
    });
  }

}
