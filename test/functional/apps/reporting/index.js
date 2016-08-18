
import {
  bdd,
  remote,
  defaultTimeout
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('reporting app', function () {
  this.timeout = defaultTimeout;

  bdd.before(function () {
    return PageObjects.remote.setWindowSize(1200,800);
  });

  require('./_reporting');
});
