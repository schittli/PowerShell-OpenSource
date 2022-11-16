## Import the Dummy-PS-Module.ps1 file. This permits loading of the module's
## functions for unit testing, without having to unload/load the whole module.
. (Join-Path -Path (Split-Path -Path $PSCommandPath) -ChildPath Dummy-PS-Module.ps1);
