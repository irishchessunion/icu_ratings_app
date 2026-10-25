//= require stimulus
// Turbo is opt-in only; existing links and forms continue as normal until they are migrated.
// turbo is included as its own module script (see layout)
Turbo.session.drive = false;

window.Stimulus = Application.start();
