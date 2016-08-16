import { bdd, defaultTimeout, scenarioManager, esClient, common } from '../../../support';

bdd.describe('monitoring app', function () {
  this.timeout = defaultTimeout;

  require('./_monitoring');

});
