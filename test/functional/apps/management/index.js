import { bdd, defaultTimeout, esClient, common } from '../../../support';

bdd.describe('settings app', function () {
  this.timeout = defaultTimeout;

  require('./_index_pattern_create_delete');

});
