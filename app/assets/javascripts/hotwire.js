//= require turbo
//= require stimulus

// Turbo is opt-in only; existing links and forms continue as normal until they are migrated.
Turbo.session.drive = false;

window.Stimulus = Application.start();
