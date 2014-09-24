Omoikane = Ember.Application.create();

Omoikane.Router.map(function() {
  this.resource('about');
  this.resource('queries', function() {
    this.resource('query', { path: ':query_id' });
  });
});

Omoikane.QueriesRoute = Ember.Route.extend({
    model: function() {
      return queries.map(function(obj) {
        return Omoikane.Query.create(obj)
      });
    }
});


Omoikane.QueryRoute = Ember.Route.extend({
  model: function(params) {
    return function() {
      return queries.findBy('id', params.query_id);
    }
  }
});


Omoikane.QueryController = Ember.ObjectController.extend({
  isEditing: false,

  actions: {
    edit: function() {
      this.set('isEditing', true);
    },

    doneEditing: function() {
      this.set('isEditing', false);
    }
  }
});

Ember.Handlebars.helper('format-time', function(tstamp) {
  return moment(tstamp).fromNow();
});

Omoikane.Query = Ember.Object.extend({
    uiStateClass: function() {
      switch(this.get('state')) {
        case "finished": return "fi-folder";
        case "running":  return "fi-refresh";
        case "pending":  return "fi-clock";
        default:         return "fi-first-aid";
      }
    }.property("state")

  , isFinished: function() {
      return this.get('state') === "finished";
    }.property('state')

  , isErrored: function() {
      return this.get('state') === "errored";
    }.property('state')

  , isPending: function() {
      return this.get('state') === "pending";
    }.property('state')

  , isRunning: function() {
      return this.get('state') === "running";
    }.property('state')

  ,  stateLastChangedAt: function() {
      if (this.get('isRunning')) {
        return this.get('startedAt');
      }

      if (this.get('isFinished') || this.get('isErrored')) {
        return this.get('finishedAt');
      }

      return this.get('submittedAt');
    }.property('state', 'submittedAt', 'startedAt', 'finishedAt')
});

var queries = [
  {
      sql: "SELECT count(DISTINCT persona_service_id)\nFROM show_interaction_bindings\nWHERE market_id = '51ee6da0-4f76-012f-6b52-4040b2a1b35b'\n  AND interaction_created_at >= '2014-09-01' AND interaction_created_at < '2014-10-01'"
    , title: "count uniques in france"
    , state: "finished"
    , author: "pablo"
    , submittedAt: moment().add(-18, "minutes")
    , startedAt: moment().add(-13, "minutes")
    , finishedAt: moment().add(-9, "minutes")
    , id: "f81e5eb0-24ed-0132-93a3-20c9d08537a9"
    , rowCount: 2
  }
, {
      sql: "SELECT count(DISTINCT persona_service_id)\nFROM show_interaction_bindings\nWHERE market_id IN '51ee6da0-4f76-012f-6b52-4040b2a1b35b'\n  AND interaction_created_at >= '2014-09-01' AND interaction_created_at < '2014-10-01'"
    , title: "count uniques in france"
    , state: "errored"
    , author: "pablo"
    , submittedAt: moment().add(-21, "minutes")
    , startedAt: moment().add(-20, "minutes")
    , finishedAt: moment().add(-20, "minutes")
    , stderr: "NOTICE: Syntax error"
    , id: "f9096b10-24ed-0132-93a3-20c9d08537a9"
  }
, {
      sql: "SELECT service_name, count(DISTINCT persona_service_id)\nFROM show_interaction_bindings\nWHERE market_id = '51ee6da0-4f76-012f-6b52-4040b2a1b35b'\n  AND interaction_created_at >= '2014-09-01' AND interaction_created_at < '2014-10-01'"
    , title: "count personas per service in france"
    , state: "running"
    , author: "françois"
    , submittedAt: moment().add(-7, "minutes")
    , startedAt: moment().add(-4, "minutes")
    , id: "f8c3d8b0-24ed-0132-93a3-20c9d08537a9"
  }
, {
      sql: "SELECT service_name, count(DISTINCT persona_service_id)\nFROM show_interaction_bindings\nWHERE market_id = '51ee6da0-4f76-012f-6b52-4040b2a1b35b'\n  AND interaction_created_at >= '2014-09-01' AND interaction_created_at < '2014-10-01'"
    , title: "count personas per service in france"
    , state: "pending"
    , author: "ousmane"
    , submittedAt: moment().add(-7, "minutes")
    , startedAt: moment().add(-4, "minutes")
    , id: "f9517570-24ed-0132-93a3-20c9d08537a9"
  }
];

// TODO: Run this on every "page" load
hljs.initHighlightingOnLoad();
