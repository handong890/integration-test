
import expect from 'expect.js';

import {
  bdd
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('users app', function describeIndexTests() {

  bdd.before(function () {
    PageObjects.common.debug('users');
    this.remote.setWindowSize(1200,800);
    return PageObjects.settings.navigateTo()
    .then(() => {
      return PageObjects.settings.clickElasticsearchUsers();
    });
  });


  bdd.describe('users', function () {

    bdd.it('should show the default elastic and kibana users', function () {
      var expectedUsers = [ 'Full Name Username Roles',
        'elastic superuser\nReserved',
        'kibana kibana\nReserved',
        'Tony Stark ironman kibanaUser',
        ''
      ];
      return PageObjects.settings.getElasticsearchUsers()
      .then((actualUsers) => {
        PageObjects.common.debug(actualUsers);
        expect(actualUsers).to.eql(expectedUsers);
      });
    });

    // bdd.it('should show disabled checkboxes for default elastic and kibana users', function () {
    // });

    bdd.it('should cancel adding new user', function () {
      var expectedUsers = [ 'Full Name Username Roles',
        'elastic superuser\nReserved',
        'kibana kibana\nReserved',
        'Tony Stark ironman kibanaUser',
        ''
      ];
      return PageObjects.settings.addUser({username: 'Lee', password: 'LeePwd',
        confirmPassword: 'LeePwd', fullname: 'LeeFirst LeeLast', email: 'lee@myEmail.com', save: false})
        .then(() => {
        return PageObjects.settings.getElasticsearchUsers()
        .then((actualUsers) => {
          PageObjects.common.debug(actualUsers);
          expect(actualUsers).to.eql(expectedUsers);
        });
      });
    });

    bdd.it('should add new user', function () {
      var expectedUsers = [ 'Full Name Username Roles',
        'LeeFirst LeeLast Lee',
        'elastic superuser\nReserved',
        'kibana kibana\nReserved',
        'Tony Stark ironman kibanaUser',
        ''
      ];
      return PageObjects.settings.addUser({username: 'Lee', password: 'LeePwd',
        confirmPassword: 'LeePwd', fullname: 'LeeFirst LeeLast', email: 'lee@myEmail.com', save: true, role: 'kibana_user'})
      .then(function () {
        return PageObjects.settings.getElasticsearchUsers()
        .then((actualUsers) => {
          PageObjects.common.debug(actualUsers);
          expect(actualUsers).to.eql(expectedUsers);
            PageObjects.common.saveScreenshot('Security Users');
        });
      });
    });

    bdd.it('should delete user', function () {
      var expectedUsers = [ 'Full Name Username Roles',
        'elastic superuser\nReserved',
        'kibana kibana\nReserved',
        'Tony Stark ironman kibanaUser',
        ''
      ];
      return PageObjects.settings.deleteUser('Lee')
      .then(() => {
        return PageObjects.settings.getElasticsearchUsers()
        .then((actualUsers) => {
          PageObjects.common.debug(actualUsers);
          expect(actualUsers).to.eql(expectedUsers);
        });
      });
    });


  });
});
