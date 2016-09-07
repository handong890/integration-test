
import expect from 'expect.js';

import {
  bdd,
  esClient
} from '../../../support';

import PageObjects from '../../../support/page_objects';

bdd.describe('watcher app', function describeIndexTests() {


  bdd.describe('simple watch', function () {
    const watchId = 'cluster_health_watch_' + new Date().getTime();
    const kbnInternVars = global.__kibana__intern__;
    const config = kbnInternVars.intern.config;

    bdd.it('should successfully add a new watch for cluster health yellow', function () {
      var cluster_health_watch = {
        "trigger" : {
          "schedule" : { "interval" : "10s" }
        },
        "input" : {
          "http" : {
            "request" : {
              "host" : config.servers.elasticsearch.hostname,
              "port" : config.servers.elasticsearch.port,
              "path" : "/_cluster/health",
              "auth" : {
                "basic" : {
                  "username" : "elastic",
                  "password" : "changeme"
                  }
                }
              }
            }
          },
          "condition" : {
            "compare" : {
              "ctx.payload.status" : { "eq" : "yellow" }
            }
          },
          "actions" : {
            "log" : {
            "logging" : {
              "text" : "executed at {{ctx.execution_time}}"
            }
          }
        }
      };
      var expectedResponse =  { _id: watchId, _version: 1, created: true };
      return esClient.index('_watcher', 'watch', watchId, cluster_health_watch)
      .then((response) => {
        PageObjects.common.debug(response);
        expect(response).to.eql(expectedResponse);
      });
    });


    bdd.it('should be successful and update revision', function () {
      return PageObjects.common.sleep(9000)
      .then(() => {
        return PageObjects.common.try(() => {
          return esClient.get('_watcher', 'watch', watchId)
          .then((response) => {
            PageObjects.common.debug('\nresponse=' + JSON.stringify(response) + '\n');
            expect(response._id).to.eql(watchId);
            expect(response.found).to.eql(true);
            expect(response._status.actions.log.last_execution.successful).to.eql(true);
            expect(response._status.version).to.be.above(1);
          });
        });
      });
    });


  });
});
