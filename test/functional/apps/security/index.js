import { bdd, defaultTimeout, esClient, common } from '../../../support';

bdd.describe('users app', function () {
  this.timeout = defaultTimeout;

  require('./_users');

});
