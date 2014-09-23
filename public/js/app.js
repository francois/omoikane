Omoikane = Ember.Application.create();

Omoikane.Router.map(function() {
  // put your routes here
});

Omoikane.IndexRoute = Ember.Route.extend({
  model: function() {
    return ['red', 'yellow', 'blue'];
  }
});
