'use strict'; // eslint-disable-line

define(function (require) {
  require('intern/dojo/node!../support/env_setup');

  const bdd = require('intern!bdd');
  const intern = require('intern');

  global.__kibana__intern__ = { intern, bdd };

  bdd.describe('kibana', function () {
    let PageObjects;
    let support;

    bdd.before(function () {
      PageObjects.init(this.remote);
      support.init(this.remote);
    });
    const supportPages = [
      'intern/dojo/node!../support/page_objects',
      'intern/dojo/node!../support'
    ];

    const requestedApps = process.argv.reduce((previous, arg) => {
      const option = arg.split('=');
      const key = option[0];
      const value = option[1];
      if (key === 'appSuites' && value) return value.split(',');
    });

    const apps = [
      'intern/dojo/node!./apps/monitoring',
      'intern/dojo/node!./apps/management',
      'intern/dojo/node!./apps/console',
      'intern/dojo/node!./apps/security',
      'intern/dojo/node!./apps/graph',
      'intern/dojo/node!./apps/metricbeat',
      'intern/dojo/node!./apps/filebeat',
      'intern/dojo/node!./apps/packetbeat',
      'intern/dojo/node!./apps/reporting',
      'intern/dojo/node!./apps/watcher'
    ].filter((suite) => {
      if (!requestedApps) return true;
      return requestedApps.reduce((previous, app) => {
        return previous || ~suite.indexOf(app);
      }, false);
    });

    require(supportPages.concat(apps), (loadedPageObjects, loadedSupport) => {
      PageObjects = loadedPageObjects;
      support = loadedSupport;
    });
  });
});
