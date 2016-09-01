
import Bluebird from 'bluebird';

import {
  defaultFindTimeout,
} from '../';

import PageObjects from './';

export default class SettingsPage {

  init(remote) {
    this.remote = remote;
  }

  clickNavigation() {
    // TODO: find better way to target the element
    return this.remote.findDisplayedByCssSelector('.app-link:nth-child(5) a').click();
  }

  clickLinkText(text) {
    return this.remote.findDisplayedByLinkText(text).click();
  }

  clickKibanaSettings() {
    return this.clickLinkText('Advanced Settings');
  }

  clickKibanaReporting() {
    return this.clickLinkText('Reporting');
  }

  clickKibanaIndicies() {
    return this.clickLinkText('Index Patterns');
  }

  clickExistingData() {
    return this.clickLinkText('Existing Data');
  }

  clickElasticsearchUsers() {
    return this.clickLinkText('Users');
  }

  clickElasticsearchRoles() {
    return this.clickLinkText('Roles');
  }

  getElasticsearchUsers() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findAllByCssSelector('tr')
    .then(function (rows) {

      function returnUsers(chart) {
        return chart.getVisibleText();
      }

      var getUsers = rows.map(returnUsers);
      return Bluebird.all(getUsers);
    });
  }

  clickNewUser() {
    return this.clickLinkText('New User');
  }

  addUser(userObj) {
    var self = this;
    // {username: 'Lee', password: 'LeePwd', confirmPassword, fullname: 'LeeFirst LeeLast', email: 'lee@myEmail.com'}
    return this.clickLinkText('New User')
    .then(function () {
      return PageObjects.common.sleep(4000);
    })
    .then(function () {
      return self.remote.setFindTimeout(defaultFindTimeout).findById('username')
      .type(userObj.username);
    })
    .then(function () {
      return self.remote.setFindTimeout(defaultFindTimeout)
      .findByCssSelector('input[ng-model="user.password"]')
      .type(userObj.password);
    })
    .then(function () {
      return self.remote.setFindTimeout(defaultFindTimeout)
      .findByCssSelector('input[ng-model="view.confirmPassword"]')
      .type(userObj.confirmPassword);
    })
    .then(function () {
      return self.remote.setFindTimeout(defaultFindTimeout).findById('fullname')
      .type(userObj.fullname);
    })
    .then(function () {
      return self.remote.setFindTimeout(defaultFindTimeout).findById('email')
      .type(userObj.email);
    })
    .then(function () {
      return PageObjects.common.sleep(4000);
    })
    .then(function () {
      return self.selectRoles(userObj.role);
    })
    .then(function () {
      return PageObjects.common.sleep(4000);
    })
    .then(function () {
      if (userObj.save === true) {
        return self.remote.setFindTimeout(defaultFindTimeout)
        .findByCssSelector('button[ng-click="saveUser(user)"]')
        .click();
      } else {
        return self.remote.setFindTimeout(defaultFindTimeout)
        .findByCssSelector('.btn-default')
        .click();
      }
    });
  }

  selectRoles(role) {
    var self = this;
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('input[aria-label="Select box"]')
    .click()
    .type('kibana_user');
    // .type(role);
  }

  deleteUser(username) {
    var alertText;
    PageObjects.common.debug('Delete user ' + username);
    return this.clickLinkText(username)
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    })
    .then(() => {
      return this.remote.setFindTimeout(defaultFindTimeout)
      .findByCssSelector('.btn-danger')
      .click();
    })
    .then(() => {
      return this.remote.getAlertText();
    })
    .then((text) => {
      alertText = text;
      PageObjects.common.debug('acceptAlert');
      return this.remote.acceptAlert();
    });
  }

  getElasticsearchUser(username) {

  }

  getAdvancedSettings(propertyName) {
    PageObjects.common.debug('in setAdvancedSettings');
    return PageObjects.common.findTestSubject('advancedSetting&' + propertyName + ' currentValue')
    .getVisibleText();
  }

  setAdvancedSettings(propertyName, propertyValue) {
    var self = this;

    return PageObjects.common.findTestSubject('advancedSetting&' + propertyName + ' editButton')
    .click()
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    })
    .then(() => {
      return PageObjects.common.sleep(1000);
    })
    .then(function setAdvancedSettingsClickPropertyValue(selectList) {
      return self.remote.setFindTimeout(defaultFindTimeout)
      .findByCssSelector('option[label="' + propertyValue + '"]')
      .click();
    })
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    })
    .then(function setAdvancedSettingsClickSaveButton() {
      return PageObjects.common.findTestSubject('advancedSetting&' + propertyName + ' saveButton')
      .click();
    })
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }

  getAdvancedSettings(propertyName) {
    var self = this;
    PageObjects.common.debug('in setAdvancedSettings');
    return PageObjects.common.findTestSubject('advancedSetting&' + propertyName + ' currentValue')
    .getVisibleText();
  }

  navigateTo() {
    return PageObjects.common.navigateToApp('settings');
  }

  getTimeBasedEventsCheckbox() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('input[ng-model="index.isTimeBased"]');
  }

  getTimeBasedIndexPatternCheckbox(timeout) {
    timeout = timeout || defaultFindTimeout;
    // fail faster since we're sometimes checking that it doesn't exist
    return this.remote.setFindTimeout(timeout)
    .findByCssSelector('input[ng-model="index.nameIsPattern"]');
  }

  getIndexPatternField() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('input[ng-model="index.name"]');
  }

  setIndexPatternField(pattern) {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('input[ng-model="index.name"]')
    .clearValue()
    .type(pattern);
  }

  getTimeFieldNameField() {
    return this.remote.setFindTimeout(defaultFindTimeout)
      .findDisplayedByCssSelector('select[ng-model="index.timeField"]');
  }

  selectTimeFieldOption(selection) {
    // open dropdown
    return this.getTimeFieldNameField().click()
    .then(() => {
      // close dropdown, keep focus
      return this.getTimeFieldNameField().click();
    })
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    })
    .then(() => {
      return PageObjects.common.try(() => {
        return this.getTimeFieldOption(selection).click()
        .then(() => {
          return this.getTimeFieldOption(selection).isSelected();
        })
        .then(selected => {
          if (!selected) throw new Error('option not selected: ' + selected);
        });
      });
    });
  }

  getTimeFieldOption(selection) {
    return this.remote.setFindTimeout(defaultFindTimeout)
      .findDisplayedByCssSelector('option[label="' + selection + '"]').click();
  }

  getCreateButton() {
    return this.remote.setFindTimeout(defaultFindTimeout)
      .findDisplayedByCssSelector('[type="submit"]');
  }

  clickDefaultIndexButton() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('button.btn.btn-success.ng-scope').click()
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }

  clickDeletePattern() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('button.btn.btn-danger.ng-scope').click();
  }

  getIndexPageHeading() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('h1.title.ng-binding.ng-isolate-scope');
  }

  getConfigureHeader() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('h1');
  }
  getTableHeader() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findAllByCssSelector('table.table.table-condensed thead tr th');
  }

  sortBy(columnName) {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findAllByCssSelector('table.table.table-condensed thead tr th span')
    .then(function (chartTypes) {
      function getChartType(chart) {
        return chart.getVisibleText()
        .then(function (chartString) {
          if (chartString === columnName) {
            return chart.click()
            .then(function () {
              return PageObjects.header.getSpinnerDone();
            });
          }
        });
      }

      var getChartTypesPromises = chartTypes.map(getChartType);
      return Bluebird.all(getChartTypesPromises);
    });
  }

  getTableRow(rowNumber, colNumber) {
    return this.remote.setFindTimeout(defaultFindTimeout)
    // passing in zero-based index, but adding 1 for css 1-based indexes
    .findByCssSelector('div.agg-table-paginated table.table.table-condensed tbody tr:nth-child(' +
      (rowNumber + 1) + ') td.ng-scope:nth-child(' +
      (colNumber + 1) + ') span.ng-binding'
    );
  }

  getFieldsTabCount() {
    var self = this;
    var selector = 'li.kbn-management-tab.active a small';

    return PageObjects.common.try(function () {
      return self.remote.setFindTimeout(defaultFindTimeout / 10)
      .findByCssSelector(selector).getVisibleText()
      .then(function (theText) {
        // the value has () around it, remove them
        return theText.replace(/\((.*)\)/, '$1');
      });
    });
  }

  getPageSize() {
    var selectedItemLabel = '';
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findAllByCssSelector('select.ng-pristine.ng-valid.ng-untouched option')
    .then(function (chartTypes) {
      function getChartType(chart) {
        var thisChart = chart;
        return chart.isSelected()
        .then(function (isSelected) {
          if (isSelected === true) {
            return thisChart.getProperty('label')
            .then(function (theLabel) {
              selectedItemLabel = theLabel;
            });
          }
        });
      }

      var getChartTypesPromises = chartTypes.map(getChartType);
      return Bluebird.all(getChartTypesPromises);
    })
    .then(() => {
      return selectedItemLabel;
    });
  }

  getPageFieldCount() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findAllByCssSelector('div.agg-table-paginated table.table.table-condensed tbody tr td.ng-scope:nth-child(1) span.ng-binding');
  }

  goToPage(pageNum) {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('ul.pagination-other-pages-list.pagination-sm.ng-scope li.ng-scope:nth-child(' +
      (pageNum + 1) + ') a.ng-binding')
    .click()
    .then(function () {
      return PageObjects.header.getSpinnerDone();
    });
  }

  openControlsRow(row) {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('table.table.table-condensed tbody tr:nth-child(' +
      (row + 1) + ') td.ng-scope div.actions a.btn.btn-xs.btn-default i.fa.fa-pencil')
    .click();
  }

  openControlsByName(name) {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('div.actions a.btn.btn-xs.btn-default[href$="/' + name + '"]')
    .click();
  }

  increasePopularity() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('button.btn.btn-default[aria-label="Plus"]')
    .click()
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }

  getPopularity() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('input[ng-model="editor.field.count"]')
    .then(input => {
      return input.getProperty('value');
    });
  }

  controlChangeCancel() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('button.btn.btn-primary[aria-label="Cancel"]')
    .click()
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }

  controlChangeSave() {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('button.btn.btn-success.ng-binding[aria-label="Update Field"]')
    .click()
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }

  setPageSize(size) {
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('form.form-inline.pagination-size.ng-scope.ng-pristine.ng-valid div.form-group option[label="' + size + '"]')
    .click()
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    });
  }

  createIndexPattern(indexPatternName = 'logstash-*') {
    // if there isn't any existing index patterns, when you go to
    // clickExistingData you will be on the "Configure an index pattern" screen
    // with logstash-* as the default.
    // But if there is an existing index pattern we have to click the "Add New" button
    // so let's check if it's there and try to click it first.
    return this.navigateTo()
    .then(() => {
      return this.clickExistingData();
    })
    .then(() => {
      return this.clickOptionalAddNewButton();
    })
    .then(() => {
      return this.setIndexPatternField(indexPatternName);
    })
    .then(() => {
      return this.selectTimeFieldOption('@timestamp');
    })
    .then(() => {
      PageObjects.common.log('click Create button now');
      return this.getCreateButton().click();
    })
    .then(function () {
      return PageObjects.common.sleep(1000);
    })
    .then(() => {
      return this.remote.acceptAlert();
    })
    .catch (() => {
      // we might be overwriting this index pattern, but that's OK
      return PageObjects.common.log('Overwriting existing [' + indexPatternName + '] pattern');
    })
    .then(() => {
      return PageObjects.header.getSpinnerDone();
    })
    .then(() => {
      return PageObjects.common.try(() => {
        return this.remote.getCurrentUrl()
          .then(function (currentUrl) {
            PageObjects.common.log('currentUrl', currentUrl);

            if (!currentUrl.match(/indices\/.+\?/)) {
              throw new Error('Index pattern not created');
            } else {
              PageObjects.common.debug('Index pattern created: ' + currentUrl);
            }
          });
      });
    });
  }

  clickOptionalAddNewButton() {
    return this.remote.setFindTimeout(3000)
    .findDisplayedByLinkText('Add New')
    .click()
    .catch(() => {
      PageObjects.common.log('didn\'t find Add New button, must be first index pattern');
    });
  }

  removeIndexPattern() {
    var alertText;

    return PageObjects.common.try(() => {
      PageObjects.common.debug('click delete index pattern button');
      return this.clickDeletePattern();
    })
    .then(() => {
      return PageObjects.common.try(() => {
        PageObjects.common.debug('getAlertText');
        return this.remote.getAlertText();
      });
    })
    .then(function (text) {
      alertText = text;
    })
    .then(() => {
      return PageObjects.common.try(() => {
        PageObjects.common.debug('acceptAlert');
        return this.remote.acceptAlert();
      });
    })
    .then(() => {
      return PageObjects.common.try(() => {
        return this.remote.getCurrentUrl()
        .then(function (currentUrl) {
          if (currentUrl.match(/indices\/.+\?/)) {
            throw new Error('Index pattern not removed');
          }
        });
      });
    })
    .then(() => {
      return alertText;
    });
  }

  getLatestReportingJob() {
    // note, 'tr' should get is the first data row (not the 'th' header row)
    // and the most recent job is always on top.
    var report = {};
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('tr > td:nth-child(1)')
    .getVisibleText()
    .then((col1) => {
      report['queryName'] = col1.split('\n')[0];
      report['type'] = col1.split('\n')[1];
    })
    .then(() => {
      return this.remote.setFindTimeout(defaultFindTimeout)
      .findByCssSelector('tr > td:nth-child(2)')
      .getVisibleText();
    })
    .then((col2) => {
      report['added'] = col2.split('\n')[0];
      report['username'] = col2.split('\n')[1];
    })
    .then(() => {
      return this.remote.setFindTimeout(defaultFindTimeout)
      .findByCssSelector('tr > td:nth-child(3)')
      .getVisibleText();
    })
    .then((col3) => {
      report['status'] = col3.split('\n')[0];
      report['completed'] = col3.split('\n')[1];
      return report;
    })
  }

  clickDownloadPdf() {
    // note, 'tr' should get is the first data row (not the 'th' header row)
    // and the most recent job is always on top.
    return this.remote.setFindTimeout(defaultFindTimeout)
    .findByCssSelector('tr > td.actions > button')
    .click();
  }

}
